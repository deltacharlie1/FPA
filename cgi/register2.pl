#!/usr/bin/perl

#  script to display the main cover sheet updating screen

read(STDIN, $Buffer, $ENV{'CONTENT_LENGTH'});

@pairs = split(/&/,$Buffer);

$Data = "";

foreach $pair (@pairs) {

	($Name, $Value) = split(/=/, $pair);

	$Value =~ tr/+/ /;
	$Value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C",hex($1))/eg;
	$Value =~ tr/\\//d;		#  Remove all back slashes
	$Value =~ s/(\'|\")/\\$1/g;
	$FORM{$Name} = $Value;

}

use DBI;
$dbh = DBI->connect("DBI:mysql:fpa");

###  Validation

$Errs = "";

#  He is asking for a reactivation email"

if ($FORM{react} =~ /Y/i) {
	$Accounts = $dbh->prepare("select regusername,regactive,regactivecode from registrations where regemail='$FORM{email}'");
	$Accounts->execute;
	if ($Accounts->rows > 0) {

		@Account = $Accounts->fetchrow;

#  Check to see if it has already been activated

		if ($Account[1] !~ /P/i || ! $Account[2]) {
			$Errs .= "<li>An account for this email address is not awaiting activation</li>\n";
		}
		else {
			$FORM{name} = $Account[0];
			$Activecode = $Account[2];
			&post_email();
		}
	}
	else {
		$Errs .= "<li>The email address has not yet been registered</li>\n";
	}
	if ($Errs) {
		print<<EOD;
Content-Type: text/html

You have the following error(s):-
<ol>$Errs</ol>
Please return to the previous screen to correct them and then re-submit.
EOD
	}
}
else {

#  New registration

	unless ($FORM{email}) { $Errs .= "<li>No email address</li>\n"; }
	if ($FORM{email} && $FORM{email} !~ /^[\w\-\.\+]+\@[a-zA-Z0-9\.\-]+\.[a-zA-z0-9]{2,4}$/) { $Errs .= "<li>Email address in incorrect format</li>\n"; }
	unless ($FORM{pwd1} && length($FORM{pwd1}) > 5) { $Errs .= "<li>No Password or your password is too short</li>\n"; }
	if ($FORM{pwd1} && $FORM{pwd1} ne $FORM{pwd2}) { $Errs .= "<li>Passwords do not match</li>\n"; }
	unless ($FORM{mem1} && length($FORM{mem1}) > 7) { $Errs .= "<li>No Memorable Word or Memorable word is too short</li>\n"; }
	if ($FORM{mem1} =~ tr/[a-z][A-Z][0-9] //cd) { $Errs .= "<li>Your memorable word can only contain letters numbers or spaces</li>\n"; }
	if ($FORM{mem1} && $FORM{mem1} ne $FORM{mem2}) { $Errs .= "<li>Memorable Words do not match</li>\n"; }
	unless ($FORM{name}) { $Errs .= "<li>Name not entered</li>\n"; }
	unless ($FORM{tc}) { $Errs .= "<li>You have not accepted our Terms and Conditions</li>\n"; }

#  Check to see if we already have this email address

	$Accounts = $dbh->prepare("select * from registrations where regemail='$FORM{email}'");
	$Accounts->execute;
	if ($Accounts->rows > 0) {
		$Errs .= "<li>The email address is already being used!&nbsp;&nbsp;Please enter a different one or contact Support Administration</li>\n";
	}

	if ($Errs) {
		print<<EOD;
Content-Type: text/html

You have the following error(s):-
<ol>$Errs</ol>
Please return to the previous screen to correct them and then re-submit.
EOD
	}
	else {

#  OK, looks like a good registrations so:-

#  1.  Save the record
#  2.  Create an empty companies record
#  3.  Create a set of nominal codes in the chart of accounts
#  4.  Send the Activation email
#  5.  Display the Welcome screen

#  Save the registration record

#  But, first, let's get the Activation code for the email

		use Digest;
		$Dig =  Digest->new("MD5");
		$Dig->add($FORM{email});
		$Activecode = $Dig->hexdigest;

		$Sts = $dbh->do("insert into registrations (regusername,regcompanyname,regemail,regpwd,regmemword,regactivecode,regregdate,reglastlogindate,regcountstartdate,regreferer) values ('$FORM{name}','$FORM{company}','$FORM{email}',password('$FORM{pwd1}'),'$FORM{mem1}','$Activecode',now(),now(),now(),'$FORM{referer}')");

#  Get the last insert id

		$New_reg_id = $dbh->last_insert_id(undef, undef, qw(registrations undef));

#  create an empty companies record (well, empty except for the Company name, contact name, contact email and email messages)

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

		$Sts = $dbh->do("insert into companies (reg_id,comname,comcontact,comemail,comvatqstart,comemailmsg,comstmtmsg) values ($New_reg_id,'$FORM{company}','$FORM{name}','$FORM{email}','2010-01-01','$Emailmsg','$Stmtmsg')");
		$New_com_id = $dbh->last_insert_id(undef, undef, qw(companies undef));

#  Create a 'customers' The owner (for expenses)

		$Sts = $dbh->do("insert into customers (acct_id,cusname,cusaddress,cuscontact,cussupplier,cusemail) values ('$New_reg_id+$New_com_id','$FORM{name} Expenses','Expenses','$FORM{name}','Y','$FORM{email}')");
		$New_exp_id = $dbh->last_insert_id(undef, undef, qw(customers undef));

#  Get bonus end date

		$Dates = $dbh->prepare("select date_add(curdate(),interval 3 month)");
		$Dates->execute;
		@Date = $Dates->fetchrow;
		$Dates->finish;

#  See if  we have a promotional code

		if ($FORM{promo} =~ /^cms35$/i) {		#  Complete Marketing Services (bookkeeper)
			$Sts = $dbh->do("update companies set comsublevel='3',comsubdue=date_add(now(),interval 30 day) where reg_id=$New_reg_id and id=$New_com_id");
			$Sts = $dbh->do("update registrations set regmembership='5' where reg_id=$New_reg_id");
		}

#  Create the reg_com record

		$Sts = $dbh->do("insert into reg_coms (reg1_id,reg2_id,com_id,comname) values ($New_reg_id,$New_reg_id,$New_com_id,'$FORM{company}')");

#  Create the temp stack record(s)

		$Sts = $dbh->do("insert into tempstacks (acct_id,caller) values ('$New_reg_id+$New_com_id','reconciliation')");
		$Sts = $dbh->do("insert into tempstacks (acct_id,caller) values ('$New_reg_id+$New_com_id','report')");

#  ... and create a set of nominal codes

		open(DATA,"nominalcodes.txt");
		$Coas = $dbh->prepare("insert into coas (acct_id,coanominalcode,coadesc,coatype,coagroup,coareport,coabalance) values (?,?,?,?,?,?,?)");
		while (<DATA>) {
			chomp($_);
			@Coa = split(/\t/,$_);
			$Coas->execute("$New_reg_id+$New_com_id",$Coa[0],$Coa[1],$Coa[2],$Coa[3],$Coa[4],'0');
		}
		$Coas->finish;
		close(DATA);

#  add to the mailing list

		my $apikey = 'a94017b54d91fe7fe1ac9166712e62c2-us2';
		my $list_id = 'b4d31d6294';
		use LWP::UserAgent;

		my $content = "method=listSubscribe&apikey=$apikey&id=$list_id&email_address=$FORM{email}&merge_vars[FNAME]=$FORM{name}&double_optin=false&send_welcome=false&output=json";

		my $ua = LWP::UserAgent->new;
		$ua->agent("FPA/0.1 ");

# Create a request
		my $req = HTTP::Request->new(POST => "http://us2.api.mailchimp.com/1.3/?$content");
		$req->content_type('application/x-www-form-urlencoded');

# Pass request to the user agent and get a response back
		my $res = $ua->request($req);


#  Send the email

		&post_email();
	}
}	
$Accounts->finish;
$dbh->disconnect;
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


Someone claiming to be $FORM{name} has used this email address to register for a FreePlus Accounts account.  If you are this person you will need to activate your account by going to the following link:-

http://www.freeplusaccounts.co.uk/cgi-bin/fpa/activate.pl?$Activecode

This code will only be valid for 24 hours from the time of registration and may be safely ignored if you are not the person registering.

(If you are unable to click on the link above please copy it and then paste it into the Address bar of your browser.)

May we take this opportunity of thanking you for your interest in the FreePlus Accounts service and we hope that you will find it useful.

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
<p>Someone claiming to be $FORM{name} has used this email address to register for a <b><i>FreePlus Accounts</i></b> account.&nbsp;&nbsp;If you are this person you will need to activate your account by going to the following link:-</p>
<p><a href="http://$Host/cgi-bin/fpa/activate.pl?$Activecode">http://www.freeplusaccounts.co.uk/cgi-bin/fpa/activate.pl?$Activecode</a></p>
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

#  finally, display the welcome screen.  We won't set his uid cookie yet.  Not until he has activated and then logs in

	print "Content-Type: text/html\n\nOK\n";
}
