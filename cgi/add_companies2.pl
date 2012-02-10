#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  Save new companies for bookkeepers

#  Processing is:-
#
#  1.  Create a new company record
#  2.  Create the necessary bank, coa records and directory
#  3.  Create a new reg_coms record for the bookkeeper
#  4.  If the email field has been filled then:-
#  5.  Create a registration record with an arbitary password
#  6.  send out an activation email

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

use CGI;
use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");

%Month  = ("Jan","01",
	   "Feb","02",
	   "Mar","03",
	   "Apr","04",
	   "May","05",
	   "Jun","06",
	   "Jul","07",
	   "Aug","08",
	   "Sep","09",
	   "Oct","10",
	   "Nov","11",
	   "Dec","12");
@Last_day = ("0","31","28","31","30","31","30","31","31","30","31","30","31");

$Curdate = `date +%m-%Y`;
chomp($Curdate);

$Data = new CGI;
%FORM = $Data->Vars;

while (( $Key,$Value) = each %FORM) {

#  Remove any bad characters

	$Value =~ s/\%2b/\+/ig;
	$Value =~ tr/\\//d;
	$Value =~ s/\'/\\\'/g;
        $FORM{$Key} = $Value;
}

#  Calculate how many new companies he can add


($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});

if ($COOKIE->{BUS} == 1 && $COOKIE->{ACCESS} > 6) {
        $Limit = '10000';
}
elsif ($COOKIE->{BUS} == 1 && $COOKIE->{ACCESS} > 4) {
        $Limit = "150";
}
elsif ($COOKIE->{BUS} == 1 && $COOKIE->{ACCESS} > 2) {
        $Limit = "15";
}
elsif ($COOKIE->{BUS} == 1) {
        $Limit = "3";
}
else {
        $Limit = '1';
}

$Companies = $dbh->prepare("select id,reg_id,comname,comcontact,comemail,date_format(comyearend,'%b') as comyearend,comvatscheme,comvatduein,comcis from companies where companies.reg_id=$Reg_id order by comname limit $Limit");
$Companies->execute;
$Remaining = $Limit - $Companies->rows;
$Companies->finish;

$FORM{data} =~ s/<(?!\/).+?>//g;
$FORM{data} =~ s/<\/tr>/\n/ig;
$FORM{data} =~ s/<\/td>/\t/ig;

@Companies = split(/\n/,$FORM{data});
$#Companies = $Remaining;

foreach $Company (@Companies) {
	@Cell = split(/\t/,$Company);

	if ($Cell[0]) {

#  Create a digest for the directory and (maybe) activation 

		$Dig = time().'.'.$$;

		use Digest;
		$Dig =  Digest->new("SHA-1");
		$Dig->add($Dig);
		$Activecode = $Dig->hexdigest;

#  Setup the email & statement messages

		$Emailmsg = sprintf<<EOD;
Please find attached our invoice no <invoice#>.

Yours sincerely

$FORM{company}
EOD

		$Stmtmsg = sprintf<<EOD;
Please find attached our statement for <month#>.

Yours sincerely

$FORM{company}
EOD

#  Create the company and associated records

		($Mth,$Yr) = split(/\-/,$Curdate);

		$Month = $Month{$Cell[3]};
		if ($Month < $Mth) {
			$Yr++;
		}
		$Last_day = $Last_day[$Month];
		if ($Yr % 4 == 0 && $Month == "02") {
			$Last_day++;
		}

		$Sts = $dbh->do("insert into companies (reg_id,comname,comcontact,comemail,comvatqstart,comemailmsg,comstmtmsg,comdocsdir,comyearend,comcis,combusiness) values ($Reg_id,'$Cell[0]','$Cell[1]','$Cell[2]','2010-01-01','$Emailmsg','$Stmtmsg','/projects/fpa_docs/$Activecode','$Yr-$Month-$Last_day','$Cell[6]','$Cell[7]')");
		$New_com_id = $dbh->last_insert_id(undef, undef, qw(companies undef));

#  Create a docs directory

		mkdir("/projects/fpa_docs/$Activecode");

#  Now update the company record with the additional info

		if ($Cell[4] !~ /N/i) {
			if ($Cell[5] =~ /^Jan/i) {
				$Cell[5] = "1";
			}
			elsif ($Cell[5] =~ /^Feb/i) {
				$Cell[5] = "2";
			}
			elsif ($Cell[5] =~ /Mar/i) {
				$Cell[5] = "3";
			}

#  Calculate the next VAT Q end

	                $Dates = $dbh->prepare("select date_format(now(),'%m'),date_format(now(),'%Y')");
        	        $Dates->execute;
                	($mth,$year) = $Dates->fetchrow;
	                $Dates->finish;

        	        $mth--;
	
        	        $vatq = $Cell[5] - 1;

                	$Months_left = $mth % 3;
	                $Cur_quarter = int($mth / 3);
        	        $VAT_due = $vatq + (3 * $Cur_quarter) + 1;
                	if ($VAT_due < $mth + 1) {
                        	$VAT_due = $VAT_due + 3;
	                }
        	        $VAT_due++;
                	if ($VAT_due > 12) {
                        	$VAT_due = $VAT_due - 12;
	                        $year++;
        	        }
                	if (length($VAT_due) < 2) { $VAT_due = '0'.$VAT_due; }

			$Sts = $dbh->do("update companies set comvatscheme='$Cell[4]',comvatduein='$Cell[5]',comvatmsgdue='$year-$VAT_due-01' where id=$New_com_id and reg_id=$Reg_id");
		}

#  If this is a CIS account then add a 1150 coa

	        if ($Cell[6] =~ /Y/i) {

        	        $COAs = $dbh->prepare("select * from coas where coanominalcode='1150' and acct_id='$Reg_id+$New_com_id'");
                	$COAs->execute;
	                unless ($COAs->rows > 0) {
        	                $dbh->do("insert into coas (acct_id,coanominalcode,coadesc,coatype,coagroup,coareport) values ('$Reg_id+$New_com_id','1150','CIS Tax','Expenses','1150','P & L')");
                	}
	                $COAs->finish;
	        }

#  Create a 'customers' The owner (for expenses)

		$Sts = $dbh->do("insert into customers (acct_id,cusname,cusaddress,cuscontact,cussupplier,cusemail) values ('$Reg_id+$New_com_id','$Cell[1] Expenses','Expenses','$Cell[1]','Y','$Cell[2]')");
		$New_exp_id = $dbh->last_insert_id(undef, undef, qw(customers undef));

#  Create the reg_com record

		$Sts = $dbh->do("insert into reg_coms (reg1_id,reg2_id,com_id,comname) values ($Reg_id,$Reg_id,$New_com_id,'$Cell[0]')");

#  Create the temp stack record(s)

		$Sts = $dbh->do("insert into tempstacks (acct_id,caller) values ('$Reg_id+$New_com_id','reconciliation')");
		$Sts = $dbh->do("insert into tempstacks (acct_id,caller) values ('$Reg_id+$New_com_id','report')");

#  ... and create a set of nominal codes

		open(DATA,"nominalcodes.txt");
		$Coas = $dbh->prepare("insert into coas (acct_id,coanominalcode,coadesc,coatype,coagroup,coareport,coabalance) values (?,?,?,?,?,?,?)");
		while (<DATA>) {
			chomp($_);
			@Coa = split(/\t/,$_);
			$Coas->execute("$Reg_id+$New_com_id",$Coa[0],$Coa[1],$Coa[2],$Coa[3],$Coa[4],'0');
		}
		$Coas->finish;
		close(DATA);

#  Do we need to set up the client as a registered user?

		if ($Cell[2] =~ /\@/ && $COOKIE->{BACCT} != '4+3') {

#  Check that we don't already have this user

			$Regs = $dbh->prepare("select reg_id from registrations where regemail='$Cell[2]' and regoptin='Y'");
			$Regs->execute;
			if ($Regs->rows > 0) {
				@Reg = $Regs->fetchrow;
				$Sts = $dbh->do("insert into reg_coms (reg1_id,reg2_id,com_id,comname) values ($Reg[0],$Reg_id,$New_com_id,'$Cell[0]')");
			}
			else {
#  set up an arbitary password

				$Pwd = "";

				while (length($Pwd) < 8) {
					$Num = int(rand 74) + 48;
					if (($Num>34 && $Num<38) || ($Num>48 && $Num<58) || ($Num>65 && $Num<91) || ($Num>96 && $Num<123)) {
						$Pwd .= chr($Num);
					}
				}

				$Sts = $dbh->do("insert into registrations (regusername,regcompanyname,regemail,regpwd,regmemword,regactivecode,regregdate,reglastlogindate,regcountstartdate,regreferer) values ('$Cell[1]','$Cell[0]','$Cell[2]',password('$Pwd'),'freeplus','$Activecode',now(),now(),now(),'$FORM{referer}')");

#  Get the last insert id

				$New_reg_id = $dbh->last_insert_id(undef, undef, qw(registrations undef));

#  Set up his reg_coms record

				$Sts = $dbh->do("insert into reg_coms (reg1_id,reg2_id,com_id,comname) values ($New_reg_id,$Reg_id,$New_com_id,'$Cell[0]')");

#  add to the mailing list

#				my $apikey = 'a94017b54d91fe7fe1ac9166712e62c2-us2';
#				my $list_id = 'b4d31d6294';
#				use LWP::UserAgent;

#				my $content = "method=listSubscribe&apikey=$apikey&id=$list_id&email_address=$FORM{email}&merge_vars[FNAME]=$FORM{name}&double_optin=false&send_welcome=false&output=json";

#				my $ua = LWP::UserAgent->new;
#				$ua->agent("FPA/0.1 ");

# Create a request
#				my $req = HTTP::Request->new(POST => "http://us2.api.mailchimp.com/1.3/?$content");
#				$req->content_type('application/x-www-form-urlencoded');

# Pass request to the user agent and get a response back
#				my $res = $ua->request($req);


#  Send the email

				&post_email();
			}
			$Regs->finish;
		}
	}
}
$dbh->disconnect;
print<<EOD;
Content-Type: text/plain
Status: 301
Location: /cgi-bin/fpa/add_companies.pl

EOD
exit;

sub post_email {

	$Addressees = "$FORM{email}";
	$Host = $ENV{SERVER_ADDR};
	if ($Host =~ /^127/) {
		$Host = "www.fpa.co.uk";
	}
	else {
		$Host = "www.freeplusaccounts.co.uk";
	}

	open(EMAIL,"| /usr/sbin/sendmail -t");
	print EMAIL <<EOD;
From: "FreePlus Registrations" <fparegistrations\@corunna.com>
To: $Addressees
bcc: doug.conran\@corunna.com
Subject: Your FreePlus Accounts Registration was successful!
Content-Type: multipart/alternative;
 boundary="=_NextPart_2rfkindysadvnqw3nerasdf";
        charset="us-ascii"
MIME-Version: 1.0

--=_NextPart_2rfkindysadvnqw3nerasdf
Content-Type: text/plain
Content-Transfer-Encoding: 7bit

================================================
         FreePlus Accounts Registration
================================================

$Cell[1] at this email address has been invited to register for a FreePlus Accounts account managed by $COOKIE->{BTAG}.  If you are this person you will need to activate your account by going to the following link:-

http://www.freeplusaccounts.co.uk/cgi-bin/fpa/activate.pl?$Activecode

Once activated, you will be able to log on to your account by going to:-

https://www.freeplusaccounts.co.uk/cgi-bin/fpa/login.pl

using this email address as your Login ID.

You have been allocated a temporary password of:  $Pwd

and a temporary Memorable word of:  freeplus

Once you have logged in you should change both of these by selecting 'Registration Details' from the 'Company' menu option.

This code will only be valid for 24 hours from the time of registration and may be safely ignored if you are not the person registering.

(If you are unable to click on the link above please copy it and then paste it into the Address bar of your browser.)

Yours Sincerely

FreePlus Accounts


--=_NextPart_2rfkindysadvnqw3nerasdf
Content-Type: text/html
Content-Transfer-Encoding: 7bit

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
<title>FreePlus Accounts Registration</title>
</head>
<body>
<p>$Cell[1] at this email address has been invited to register for a <b><i>FreePlus Accounts</i></b> account managed by $COOKIE->{BTAG}.&nbsp;&nbsp;If you are this person you will need to activate your account by going to the following link:-</p>
<p><a href="http://www.freeplusaccounts.co.uk/cgi-bin/fpa/activate.pl?$Activecode">http://www.freeplusaccounts.co.uk/cgi-bin/fpa/activate.pl?$Activecode</a></p>
<p>Once activated, you will be able to log on to your account by going to:-</p>
<p><a href="https://www.freeplusaccounts.co.uk/cgi-bin/fpa/login.pl">https://www.freeplusaccounts.co.uk/cgi-bin/fpa/login.pl</a></p>
<p>using this email as your Login ID<p>
<p>You have been allocated a temporary password of:&nbsp;&nbsp;<b>$Pwd</b><br/>
and a temporary Memorable word of:&nbsp;&nbsp;<b>freeplus</b></p>
<p>Once you have logged in you should change both of these by selecting 'Registration Details' from the 'Company' menu option.</p>
<p>This code will only be valid for 24 hours from the time of registration and may be safely ignored if you are not the person registering.<br />
(If you are unable to click on the link above please copy it and then paste it into the Address bar of your browser)</p>
<p>May we take this opportunity of thanking you for your interest in the <b><i>FreePlus Accounts</i></b> service and we hope that you will find it useful.</p>
<p>Yours Sincerely</p>
<p>FreePlus Accounts</p>
</body>
</html>

--=_NextPart_2rfkindysadvnqw3nerasdf--
EOD
	close(EMAIL);
}
