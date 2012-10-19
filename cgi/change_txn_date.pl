#!/usr/bin/perl

#  Script to change an errorneously entered date

use CGI;

$ACCESS_LEVEL = 1;

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

$Data = new CGI;
%FORM = $Data->Vars;

while (( $Key,$Value) = each %FORM) {

#  Remove any bad characters

        $Value =~ tr/\\//d;
        $Value =~ s/\'/\\\'/g;
        $FORM{$Key} = $Value;
}

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");

#  Change the transaction record date

$Sts = $dbh->do("update transactions set txndate=str_to_date('$FORM{newdate}','%d-%b-%y') where acct_id='$COOKIE->{ACCT}' and id=$FORM{id}");

#  Change the nominals dates for this txn

$Sts = $dbh->do("update nominals set nomdate=str_to_date('$FORM{newdate}','%d-%b-%y') where acct_id='$COOKIE->{ACCT}' and link_id=$FORM{id} and nomtype='T'");

#  Change vataccrual date if Cash scheme

if ($COOKIE->{VAT} =~ /C/i) {
	$Sts = $dbh->do("update vataccruals set acrprintdate=str_to_date('$FORM{newdate}','%d-%b-%y') where acct_id='$COOKIE->{ACCT}' and acrtxn_id=$FORM{id}");
}

#  Now update the date get each inv_txn so that we can change invoice related dates

$Sts = $dbh->do("update inv_txns set itdate=str_to_date('$FORM{newdate}','%d-%b-%y') where acct_id='$COOKIE->{ACCT}' and txn_id=$FORM{id}");

$Invtxns = $dbh->prepare("select inv_id from inv_txns where txn_id=$FORM{id} and acct_id='$COOKIE->{ACCT}'");
$Invtxns->execute;
while (@Invtxn = $Invtxns->fetchrow) {

#  Change the invoice print date

	$Sts = $dbh->do("update invoices set invprintdate=str_to_date('$FORM{newdate}','%d-%b-%y') where acct_id='$COOKIE->{ACCT}' and id=$Invtxn[0]");

#  Change the nominals dates for this invoice

	$Sts = $dbh->do("update nominals set nomdate=str_to_date('$FORM{newdate}','%d-%b-%y') where acct_id='$COOKIE->{ACCT}' and link_id=$Invtxn[0] and nomtype='S'");

#  Change the vataccrual date if Standard scheme

	if ($COOKIE->{VAT} =~ /S/i) {
		$Sts = $dbh->do("update vataccruals set acrprintdate=str_to_date('$FORM{newdate}','%d-%b-%y') where acct_id='$COOKIE->{ACCT}' and acrtxn_id=$Invtxn[0]");
	}

#  Finally, insert an audit trail comment

$Txns = $dbh->prepare("select txntxnno,txncusname,txnremarks from transactions where acct_id='$COOKIE->{ACCT}' and id=$FORM{id}");
$Txns->execute;
@Txn = $Txns->fetchrow;
$Txns->finish;

$Sts = $dbh->do("insert into audit_trails (acct_id,link_id,audtype,audaction,audtext,auduser) values ('$COOKIE->{ACCT}',$FORM{id},'','change','Date changed to $FORM{newdate} for txn $Txn[0], $Txn[1] ($Txn[2])','$COOKIE->{USER}')");

}
$Invtxns->finish;
print<<EOD;
Content-Type:text/plain

OK-
EOD
$dbh->disconnect;
exit;
