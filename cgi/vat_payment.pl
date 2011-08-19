#!/usr/bin/perl

#  Script to create a vat transaction

$ACCESS_LEVEL = 1;

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

use CGI;

$Data = new CGI;
%FORM = $Data->Vars;

# print FILE "Starting to split parameters\n";

while (( $Key,$Value) = each %FORM) {

#  Remove any bad characters

        $Value =~ tr/\\//d;
        $Value =~ s/\'/\\\'/g;
        $FORM{$Key} = $Value;

# print "$Key = $Value\n";
# print FILE  "$Key = $Value\n";
}
# exit;

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");
unless ($COOKIE->{NO_ADS}) {
	require "/usr/local/git/fpa/cgi/display_adverts.ph";
	&display_adverts();
}


if ($FORM{vatid}) {

#  Set the date if not already set

	if ($FORM{vatdte}) {
		$Date = "str_to_date('$FORM{vatdte}','%d-%b-%y')";
	}
	else {
		$Date = "now()";
	}

#  Get the amounts to be deducted from and added to the coa

	$Vatreturns = $dbh->prepare("select perbox3,perbox4,perbox5,perquarter from vatreturns where acct_id='$COOKIE->{ACCT}' and id=$FORM{vatid}");
	$Vatreturns->execute;
	@Vatreturn = $Vatreturns->fetchrow;
	$Vatreturns->finish;

#  Remember that a minus amount is a refund to us, so reverse the sign

	$Vatreturn[2] = 0 - $Vatreturn[2];

	if ($Vatreturn[2] > 0) {
		$Vatpay = "Refund";
		$Txndir = "vat";
		$Txnaction = "received from";
	}
	else {
		$Vatpay = "Payment";
		$Txndir = "vat";
		$Txnaction = "paid to";
	}

#  Get the next transaction no

        ($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});
        $Companies = $dbh->prepare("select comnexttxn from companies where reg_id=$Reg_id and id=$Com_id");
        $Companies->execute;
        @Company = $Companies->fetchrow;
        $Companies->finish;

        $FORM{txnno} = $Company[0];
        $Sts = $dbh->do("update companies set comnexttxn=comnexttxn+1 where reg_id=$Reg_id and id=$Com_id");

#  create a transaction record

        $Sts = $dbh->do("insert into transactions (acct_id,link_id,txncusname,txnmethod,txnamount,txndate,txntxntype,txnremarks,txntxnno) values ('$COOKIE->{ACCT}',$FORM{vatid},'VAT $Vatpay','1200','$Vatreturn[2]',$Date,'$Txndir','VAT Quarter $Vatreturn[3]','$FORM{txnno}')");
	$New_txn_id = $dbh->last_insert_id(undef, undef, qw(transactions undef));

#  Bank

        $Sts = $dbh->do("update coas set coabalance=coabalance + '$Vatreturn[2]' where acct_id='$COOKIE->{ACCT}' and coanominalcode='1200'");
	$Sts = $dbh->do("insert into nominals (acct_id,link_id,nomtype,nomcode,nomamount,nomdate) values ('$COOKIE->{ACCT}',$New_txn_id,'T','1200','$Vatreturn[2]',$Date)");

#  VAT Output

        $Sts = $dbh->do("update coas set coabalance=coabalance - '$Vatreturn[0]' where acct_id='$COOKIE->{ACCT}' and coanominalcode='2100'");
	$Sts = $dbh->do("insert into nominals (acct_id,link_id,nomtype,nomcode,nomamount,nomdate) values ('$COOKIE->{ACCT}',$New_txn_id,'T','2100','-$Vatreturn[0]',$Date)");

#  VAT Input 

        $Sts = $dbh->do("update coas set coabalance=coabalance - '$Vatreturn[1]' where acct_id='$COOKIE->{ACCT}' and coanominalcode='1400'");
	$Sts = $dbh->do("insert into nominals (acct_id,link_id,nomtype,nomcode,nomamount,nomdate) values ('$COOKIE->{ACCT}',$New_txn_id,'T','1400','-$Vatreturn[1]',$Date)");

#  Update the VAT Return to 'Paid'

	$Sts = $dbh->do("update vatreturns set perstatus='Paid', perstatusdate=now() where acct_id='$COOKIE->{ACCT}' and id=$FORM{vatid}");

#  Update comvatcontrol

        ($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});
        $Sts = $dbh->do("update companies set comvatcontrol=comvatcontrol - '$Vatreturn[2]' where reg_id=$Reg_id and id=$Com_id");

#  Audit trail

	$Vatreturn[2] =~ tr/-//d;
        $Sts = $dbh->do("insert into audit_trails (acct_id,link_id,audtype,audaction,audtext,auduser) values ('$COOKIE->{ACCT}',$FORM{vatid},'transactions','income','VAT $Vatpay of &pound;$Vatreturn[2] $Txnaction HMRC','$COOKIE->{USER}')");

}
print<<EOD;
Content-Type:text/html
Status: HTTP/1.1 204 No Content

EOD

$dbh->disconnect;
exit;
