#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to update Company Details

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

use GD;
use CGI;
use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");

$Data = new CGI;
%FORM = $Data->Vars;

# print "Content-Type: text/plain\n\n";

while (( $Key,$Value) = each %FORM) {

#  Remove any bad characters

	$Value =~ tr/\\//d;
	$Value =~ s/\'/\\\'/g;
        $FORM{$Key} = $Value;

#	print "$Key = $Value\n";

}
# exit;

$handle = $Data->upload("comlogo");

$Img = "";
while (<$handle>) {
	$Img .= $_;
}

#  Do some basic validation

$Errs = "";

unless ($FORM{comname}) { $Errs .= "<li>No Company Name</li>\n"; }
unless ($FORM{comaddress}) { $Errs .= "<li>No Address</li>\n"; }
unless ($FORM{compostcode}) { $Errs .= "<li>No Post Code</li>\n"; }
unless ($FORM{combusiness}) { $Errs .= "<li>No Type of Business</li>\n"; }
if ($FORM{comvatscheme} !~ /N/i && ! $FORM{comvatno}) { $Errs .= "<li>No VAT Number</li>\n"; }
if ($FORM{comvatscheme} !~ /N/i && ! $FORM{comvatduein}) { $Errs .= "<li>No VAT Quarter End selected</li>\n"; }
unless ($FORM{comyearend}) { $Errs .= "<li>No Accounting Year End selected</li>\n"; }
unless ($FORM{comnextsi}) { $Errs .= "<li>No Sales Invoice Number entered</li>\n"; }
unless ($FORM{comnextpi}) { $Errs .= "<li>No Purchase Invoice Number entered</li>\n"; }
unless (length($Img) < 36000) { $Errs .= "<li>Your logo file is too large, please load a smaller image</li>\n"; }

if ($Errs) {
	print<<EOD;
Content-Type: text/html

Errors!

You have the following errors:-<ol>$Errs</ol>Please correct and re-submit
EOD
}
else {

	($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});

	if ($Img) {
		$Image1 = new GD::Image($Img);
		($width,$height) = $Image1->getBounds();
		if ($width > 144 || $height > 48) {
			if ($width > $height * 3) {
				$W1 = 144;
				$H1 = int(48 * $width / $height);
			}
			else {
				$H1 = 48;
				$W1 = int(144 * $height / $width);
			}
	
			$Image2 = new GD::Image($W1,$H1);
			$Image2->copyResampled($Image1,0,0,0,0,$W1,$H1,$width,$height);
			$Img = $Image2->png;
		}
		$Img =~ s/([\\\"\'])/\\$1/g;
#		$Img =~ s/\'/\\\'/g;
	}

	unless ($FORM{comvatscheme} =~ /N/i) {

#  Calculate the current VAT Q end

#  get the current month

		$Dates = $dbh->prepare("select date_format(now(),'%m')");
		$Dates->execute;
		@Date = $Dates->fetchrow;

		$NextQ = $FORM{comduein};

#  Determine the next Q end

		while ($Date[0] > $NextQ) {
			$NextQ += 3;
		}

#  Calculate how many months to add to the current month to get the next Q end

		$Months_to_add = $NextQ - $Date[0];

#  Finally, calculate when the next vat message is due (if quarter end = 2010-03-31 then msg due = 2010-04-01 (ie plus 1 day))

		$Dates = $dbh->prepare("select last_day(date_add(now(),interval $Months_to_add month)),date_add(last_day(date_add(now(),interval $Months_to_add month)),interval 1 day)");
		$Dates->execute;
		@Date = $Dates->fetchrow;
		$Dates->finish;
	}

#  Check whether we have an image to upload

	if ($Img) {
		$Sts = $dbh->do("update companies set comname='$FORM{comname}',comregno='$FORM{comregno}',comaddress='$FORM{comaddress}',compostcode='$FORM{compostcode}',comtel='$FORM{comtel}',combusiness='$FORM{combusiness}',comcontact='$FORM{comcontact}',comemail='$FORM{comemail}',comyearend='$FORM{comyearend}',comnextsi='$FORM{comnextsi}',comnextpi='$FORM{comnextpi}',comvatscheme='$FORM{comvatscheme}',comvatno='$FORM{comvatno}',comvatduein='$FORM{comvatduein}',comvatmsgdue='$Date[1]',comlogo='$Img',comcompleted='1',comemailmsg='$FORM{comemailmsg}',comstmtmsg='$FORM{comstmtmsg}' where reg_id=$Reg_id and id=$Com_id");
	}
	else {
		$Sts = $dbh->do("update companies set comname='$FORM{comname}',comregno='$FORM{comregno}',comaddress='$FORM{comaddress}',compostcode='$FORM{compostcode}',comtel='$FORM{comtel}',combusiness='$FORM{combusiness}',comcontact='$FORM{comcontact}',comemail='$FORM{comemail}',comyearend='$FORM{comyearend}',comnextsi='$FORM{comnextsi}',comnextpi='$FORM{comnextpi}',comvatscheme='$FORM{comvatscheme}',comvatno='$FORM{comvatno}',comvatduein='$FORM{comvatduein}',comvatmsgdue='$Date[1]',comcompleted='1',comemailmsg='$FORM{comemailmsg}',comstmtmsg='$FORM{comstmtmsg}' where reg_id=$Reg_id and id=$Com_id");
	}

#  Check to see if we have any Current Account data (ie a bank name)

        $Accts = $dbh->prepare("select id from accounts where acct_id='$COOKIE->{ACCT}' and acctype='1200'");
        $Accts->execute;
        if ($Accts->rows > 0) {         #  Existing Account
                @Acct = $Accts->fetchrow;
                $Sts = $dbh->do("update accounts set accname='$FORM{curname}',accsort='$FORM{cursort}',accacctno='$FORM{curacctno}' where acct_id='$COOKIE->{ACCT}' and id=$Acct[0]");
        }
        else {                          #  New Account
                $Sts = $dbh->do("insert into accounts (acct_id,acctype,accshort,accname,accsort,accacctno) values ('$COOKIE->{ACCT}','1200','Current','$FORM{curname}','$FORM{cursort}','$FORM{curacctno}')");
        }

#  Check to see if we have any Deposit Account data (ie a bank name)

        $Accts = $dbh->prepare("select id from accounts where acct_id='$COOKIE->{ACCT}' and acctype='1210'");
        $Accts->execute;
        if ($Accts->rows > 0) {         #  Existing Account
                @Acct = $Accts->fetchrow;
                $Sts = $dbh->do("update accounts set accname='$FORM{depname}',accsort='$FORM{depsort}',accacctno='$FORM{depacctno}' where acct_id='$COOKIE->{ACCT}' and id=$Acct[0]");
        }
        else {                          #  New Account
                $Sts = $dbh->do("insert into accounts(acct_id,acctype,accshort,accname,accsort,accacctno) values ('$COOKIE->{ACCT}','1210','Deposit','$FORM{depname}','$FORM{depsort}','$FORM{depacctno}')");
        }

#  Check to see if we have any Credit Card

        $Accts = $dbh->prepare("select id from accounts where acct_id='$COOKIE->{ACCT}' and acctype='2010'");
        $Accts->execute;
        if ($Accts->rows > 0) {         #  Existing Account
                @Acct = $Accts->fetchrow;
                $Sts = $dbh->do("update accounts set accname='$FORM{depname}' where acct_id='$COOKIE->{ACCT}' and id=$Acct[0]");
        }
        else {                          #  New Account
                $Sts = $dbh->do("insert into accounts(acct_id,acctype,accshort,accname) values ('$COOKIE->{ACCT}','2010','Card','$FORM{cardname}')");
        }
	$Accts->finish;

#  Get the default menu screen and update the comcompleted flag in registrations

	$Regs = $dbh->prepare("select regdefaultmenu,regactive from registrations where reg_id=$Reg_id");
	$Regs->execute;
	@Reg = $Regs->fetchrow;
	$Regs->finish;
	
	if ($Reg[1] =~ /P/i) {
	        $Vars = {
                title => 'Registration Accepted',
                client => { 'comname' => $FORM{company}, 'comcontact' => $FORM{name}, 'comemail' => $FORM{email}, 'comnextsi' => '100001', 'comnextpi' => '100001' }
	        };
        	print "Content-Type: text/html\n";
		print "Set-Cookie: fpa-comname=$FORM{comname}; path=/;\n\n";
        	$tt->process('company_setup.tt',$Vars);
	}
	else {
		print<<EOD;
Content-Type: text/plain

OK-company_details.pl

EOD
	}
}
$dbh->disconnect;
exit;
