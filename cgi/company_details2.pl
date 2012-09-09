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

#  Get existing details

	$Companies = $dbh->prepare("select comvatscheme,comcis from companies where reg_id=$Reg_id and id=$Com_id");
	$Companies->execute;
	$Company = $Companies->fetchrow_hashref;
	$Companies->finish;

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
			$Img = $Image2->jpeg();
		}
#		$Img =~ s/([\\\"\'])/\\$1/g;
#		$Img =~ s/\'/\\\'/g;
		use  MIME::Base64;
		$Img = encode_base64($Img);
	}

#  Add an extra nominal code if registered for CIS (and no code exists)

	if ($FORM{comcis} =~ /Y/i && $FORM{comcis} !~ /$Company->{comcis}/i) {

#  See if there is already a 1150 nomincal code

		$COAs = $dbh->prepare("select * from coas where coanominalcode='1150' and acct_id='$COOKIE->{ACCT}'");
		$COAs->execute;
		unless ($COAs->rows > 0) {
			$dbh->do("insert into coas (acct_id,coanominalcode,coadesc,coatype,coagroup,coareport) values ('$COOKIE->{ACCT}','1150','CIS Tax','Current Assets','1150','Balance Sheet')");
		}
		$COAs->finish;
	}

	unless ($FORM{comvatscheme} =~ /N/i) {

#  Calculate the current VAT Q end

#  get the current month

		$Dates = $dbh->prepare("select date_format(now(),'%m'),date_format(now(),'%Y')");
		$Dates->execute;
		($mth,$year) = $Dates->fetchrow;
		$Dates->finish;

		$mth--;

		$vatq = $FORM{comvatduein} - 1;

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
	}

#  Check whether we have an image to upload

	if ($Img) {
		$Sts = $dbh->do("update companies set comname='$FORM{comname}',comregno='$FORM{comregno}',comaddress='$FORM{comaddress}',compostcode='$FORM{compostcode}',comtel='$FORM{comtel}',combusiness='$FORM{combusiness}',comcontact='$FORM{comcontact}',comemail='$FORM{comemail}',comyearend='$FORM{comyearend}',comnextsi='$FORM{comnextsi}',comnextpi='$FORM{comnextpi}',comvatscheme='$FORM{comvatscheme}',comvatno='$FORM{comvatno}',comvatduein='$FORM{comvatduein}',comvatmsgdue='$year-$VAT_due-01',comlogo='$Img',comcompleted='1',comemailmsg='$FORM{comemailmsg}',comstmtmsg='$FORM{comstmtmsg}',comcis='$FORM{comcis}',comlayout='$FORM{comlayout}',comsoletrader='$FORM{comsoletrader}' where reg_id=$Reg_id and id=$Com_id");
	}
	else {
		$Sts = $dbh->do("update companies set comname='$FORM{comname}',comregno='$FORM{comregno}',comaddress='$FORM{comaddress}',compostcode='$FORM{compostcode}',comtel='$FORM{comtel}',combusiness='$FORM{combusiness}',comcontact='$FORM{comcontact}',comemail='$FORM{comemail}',comyearend='$FORM{comyearend}',comnextsi='$FORM{comnextsi}',comnextpi='$FORM{comnextpi}',comvatscheme='$FORM{comvatscheme}',comvatno='$FORM{comvatno}',comvatduein='$FORM{comvatduein}',comvatmsgdue='$year-$VAT_due-01',comcompleted='1',comemailmsg='$FORM{comemailmsg}',comstmtmsg='$FORM{comstmtmsg}',comcis='$FORM{comcis}',comlayout='$FORM{comlayout}',comsoletrader='$FORM{comsoletrader}' where reg_id=$Reg_id and id=$Com_id");
	}

#  update the dividends/drawings coa

	if ($FORM{comsoletrader} =~ /Y/i) {
		$Sts = $dbh->do("update coas set coadesc='Drawings' where acct_id='$COOKIE->{ACCT}' and coanominalcode='3050'");
	}
	else {
		$Sts = $dbh->do("update coas set coadesc='Dividends' where acct_id='$COOKIE->{ACCT}' and coanominalcode='3050'");
	}

#  Check to see if the comvatscheme has gone from Cash Accounting to Standard Accounting

	if ($Company->{comvatscheme} =~ /C/i && $FORM{comvatscheme} =~ /S/i) {

#  Scoop up all unpaid VAT and put it into vataccruals

		$Invoices = $dbh->prepare("select invoices.id as invid,invtype,invprintdate,invcoa,(invtotal+invvat-sum(acrtotal+acrvat)) as balance,if(sum(acrtotal),invtotal-sum(acrtotal),invtotal) as totdiff,if(sum(acrvat),invvat-sum(acrvat),invvat) as vatdiff from invoices left join inv_txns on (invoices.id=inv_txns.inv_id and invoices.acct_id=inv_txns.acct_id) left join vataccruals on (inv_txns.id=vataccruals.acrtxn_id and inv_txns.acct_id=vataccruals.acct_id) where invoices.acct_id='$COOKIE->{ACCT}' and invoices.invstatuscode>2 group by invoices.invinvoiceno having isnull(balance) or balance<>0");
		$Invoices->execute;

#  For each not fully paid invoice, create a vataccrual record
		$TotVAT = 0;

		while($Invoice = $Invoices->fetchrow_hashref) {
			$Sts = $dbh->do("insert into vataccruals (acct_id,acrtotal,acrvat,acrprintdate,acrnominalcode,acrtxn_id) values ('$COOKIE->{ACCT}','$Invoice->{totdiff}','$Invoice->{vatdiff}','$Invoice->{invprintdate}','$Invoice->{invcoa}',$Invoice->{invid})");
			$TotVAT += $Invoice->{vatdiff};
		}
		$Invoices->finish;

#  update the comvatcontrol

		$Sts = $dbh->do("update companies set comvatcontrol=comvatcontrol+'$TotVAT' where reg_id=$Reg_id and id=$Com_id");
	}

#  Check to see if we have any Current Account data (ie a bank name)

        $Accts = $dbh->prepare("select id from accounts where acct_id='$COOKIE->{ACCT}' and acctype='1200'");
        $Accts->execute;
        if ($Accts->rows > 0) {         #  Existing Account
                @Acct = $Accts->fetchrow;
                $Sts = $dbh->do("update accounts set accname='$FORM{curname}',accsort='$FORM{cursort}',accacctno='$FORM{curacctno}',accnewrec='$FORM{curnewrec}' where acct_id='$COOKIE->{ACCT}' and id=$Acct[0]");
        }
        else {                          #  New Account
                $Sts = $dbh->do("insert into accounts (acct_id,acctype,accshort,accname,accsort,accacctno,accnewrec) values ('$COOKIE->{ACCT}','1200','Current','$FORM{curname}','$FORM{cursort}','$FORM{curacctno}','$FORM{curnewrec}')");
        }

#  Check to see if we have any Deposit Account data (ie a bank name)

        $Accts = $dbh->prepare("select id from accounts where acct_id='$COOKIE->{ACCT}' and acctype='1210'");
        $Accts->execute;
        if ($Accts->rows > 0) {         #  Existing Account
                @Acct = $Accts->fetchrow;
                $Sts = $dbh->do("update accounts set accname='$FORM{depname}',accsort='$FORM{depsort}',accacctno='$FORM{depacctno}',accnewrec='$FORM{depnewrec}' where acct_id='$COOKIE->{ACCT}' and id=$Acct[0]");
        }
        else {                          #  New Account
                $Sts = $dbh->do("insert into accounts(acct_id,acctype,accshort,accname,accsort,accacctno,accnewrec) values ('$COOKIE->{ACCT}','1210','Deposit','$FORM{depname}','$FORM{depsort}','$FORM{depacctno}','$FORM{depnewrec}')");
        }

#  Check to see if we have any Credit Card

        $Accts = $dbh->prepare("select id from accounts where acct_id='$COOKIE->{ACCT}' and acctype='2010'");
        $Accts->execute;
        if ($Accts->rows > 0) {         #  Existing Account
                @Acct = $Accts->fetchrow;
                $Sts = $dbh->do("update accounts set accname='$FORM{cardname}',accnewrec='$FORM{cardnewrec}' where acct_id='$COOKIE->{ACCT}' and id=$Acct[0]");
        }
        else {                          #  New Account
                $Sts = $dbh->do("insert into accounts(acct_id,acctype,accshort,accname,accnewrec) values ('$COOKIE->{ACCT}','2010','Card','$FORM{cardname}','$FORM{cardnewrec}')");
        }
	$Accts->finish;

#  Get the default menu screen and update the comcompleted flag in registrations

	$Regs = $dbh->prepare("select regdefaultmenu,regactive from registrations where reg_id=$Reg_id");
	$Regs->execute;
	@Reg = $Regs->fetchrow;
	$Regs->finish;
	
	if ($Reg[1] =~ /P/i) {
	        $Vars = {
	 ads => $Adverts,
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
