#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to reverse erroneous transactions (other than invoice ones)

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

($Txn_id,$Acctype) = split(/\?/,$ENV{QUERY_STRING});

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");
($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});

#  First get details of the transaction to be deleted

$Txns = $dbh->prepare("select * from transactions where acct_id='$COOKIE->{ACCT}' and id=$Txn_id");
$Txns->execute;

if ($Txns->rows > 0) {
	$Txn = $Txns->fetchrow_hashref;

	if ($Txn->{txntxntype} =~ /transfer/i) {

#  This is a funds transfer so we have to remove the other transaction
		
		$Txnamount = 0 - $Txn->{txnamount};
		$Txns2 = $dbh->prepare("select * from transactions where acct_id='$COOKIE->{ACCT}' and txntxntype='transfer' and txncreated='$Txn->{txncreated}' and txnamount='$Txnamount'");
		$Txns2->execute;

		if ($Txns2->rows > 0) {
			$Txn2 = $Txns2->fetchrow_hashref;
		}
		$Txns2->finish;
	}
	&reverse_txn();
	
	if ($Txn->{txntxntype} =~ /transfer/i) {

#  Now re get the second record using the id

  		$Txns = $dbh->prepare("select * from transactions where acct_id='$COOKIE->{ACCT}' and txntxntype='transfer' and id=$Txn2->{id}");
		$Txns->execute;
		$Txn = $Txns->fetchrow_hashref;
		&reverse_txn();
	}
}
$Invoices->finish;
$Txns->finish;
$dbh->disconnect;

print<<EOD;
Content-Type: text/html
Status: 302
Location: /cgi-bin/fpa/list_txns.pl

EOD
exit;

sub reverse_txn {

#  Now get the related inv_txn

	$Inv_txns = $dbh->prepare("select * from inv_txns where acct_id='$COOKIE->{ACCT}' and txn_id=$Txn->{id}");
	$Inv_txns->execute;

	if ($Inv_txns->rows > 0) {
		$Inv_txn = $Inv_txns->fetchrow_hashref;

#  Get details of the invoice to be voided

		$Invoices = $dbh->prepare("select * from invoices where acct_id='$COOKIE->{ACCT}' and id=$Inv_txn->{inv_id}");
		$Invoices->execute;
		$Invoice = $Invoices->fetchrow_hashref;

#  We don't need this test!!		if ($Invoice->{invtype} =~ /S/i) {

#  Adjust the invpaid and invpaidvat

		$Sts = $dbh->do("update invoices set invpaid=invpaid-'$Inv_txn->{itnet}',invpaidvat=invpaidvat-'$Inv_txn->{itvat}' where acct_id='$COOKIE->{ACCT}' and id=$Inv_txn->{inv_id}");

#  check to see how to adjust the status and paid date

		$T_Invoices = $dbh->prepare("select to_days(invprintdate),to_days(invduedate),to_days(now()),invpaid from invoices where acct_id='$COOKIE->{ACCT}' and id=$Inv_txn->{inv_id}");
		$T_Invoices->execute;
		@T_Invoice = $T_Invoices->fetchrow;
		$T_Invoices->finish;

		if ($T_Invoice[3] =~ /0.00/) {
			$Sts = $dbh->do("update invoices set invpaiddate=NULL where acct_id='$COOKIE->{ACCT}' and id=$Inv_txn->{inv_id}");
		}
		if ($T_Invoice[1] < $T_Invoice[2]) {
			$Sts = $dbh->do("update invoices set invstatus='Overdue',invstatuscode='9' where acct_id='$COOKIE->{ACCT}' and id=$Inv_txn->{inv_id}");
		}
		elsif (($T_Invoice[1] - $T_Invoice[2]) < ($T_Invoice[1] - $T_Invoice[0]) * 0.7) {
			$Sts = $dbh->do("update invoices set invstatus='Due',invstatuscode='6' where acct_id='$COOKIE->{ACCT}' and id=$Inv_txn->{inv_id}");
		}
		else {
			$Sts = $dbh->do("update invoices set invstatus='Printed',invstatuscode='3' where acct_id='$COOKIE->{ACCT}' and id=$Inv_txn->{inv_id}");
		}
#  Deal with VAT accruals if this is a Cash scheme

		if ($COOKIE->{VAT}=~ /C/i) {

#  Delete any vataccruals that have been added (we assume that they have not yet been allocated to a VAT Return!)

			$Sts = $dbh->do("delete from vataccruals where acct_id='$COOKIE->{ACCT}' and acrtxn_id=$Inv_txn->{id}");
		}
	}
	$Inv_txns->finish;

#  Delete inv_txns

	$Sts = $dbh->do("delete from inv_txns where acct_id='$COOKIE->{ACCT}' and txn_id=$Txn->{id}");

#  Revert coas based on nominal entries

	$Noms = $dbh->prepare("select * from nominals where acct_id='$COOKIE->{ACCT}' and link_id=$Txn->{id}");
	$Noms->execute;
	while ($Nom = $Noms->fetchrow_hashref) {
		$Sts = $dbh->do("update coas set coabalance=coabalance - '$Nom->{nomamount}' where acct_id='$COOKIE->{ACCT}' and coanominalcode='$Nom->{nomcode}'");
	}
	$Noms->finish;

#  Delete the nominal ledger entries

	$Sts = $dbh->do("delete from nominals where acct_id='$COOKIE->{ACCT}' and nomtype='T' and link_id=$Txn->{id}");

#  Delete the transaction

	$Sts = $dbh->do("delete from transactions where acct_id='$COOKIE->{ACCT}' and id=$Txn->{id}");
	$Txns->finish;

#  If this is a VAT transaction then revert the VAT Return to 'Filed'

	if ($Txn->{txntxntype} =~ /vat/i) {
		$Sts = $dbh->do("update vatreturns set perstatus='Filed' where acct_id='$COOKIE->{ACCT}' and id=$Txn->{link_id}");
	}

#  Write an audit trail comment

	$Sts = $dbh->do("insert into audit_trails (acct_id,link_id,audtype,audaction,audtext,auduser) values ('$COOKIE->{ACCT}',$Txn->{id},'reverse_txns.pl','adj','TXN: $Txn->{txntxnno} [$Txn->{txncusname} ($Txn->{txnremarks})] deleted','$COOKIE->{USER}')");

#  Decrement all higher Transaction nos

	$Sts = $dbh->do("update transactions set txntxnno=cast(txntxnno as unsigned)-1 where acct_id='$COOKIE->{ACCT}' and cast(txntxnno as unsigned) > $Txn->{txntxnno}");

#  Decrement the comnexttxn

	$Sts = $dbh->do("update companies set comnexttxn=cast(comnexttxn as unsigned) - 1 where reg_id=$Reg_id and id=$Com_id");
}
