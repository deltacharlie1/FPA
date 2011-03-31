#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to reverse erroneous transactions (other than invoice ones)

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

($Txn_id,$Acctype) = split(/\?/,$ENV{QUERY_STRING});

use DBI;
my $dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");
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
$Txns->finish;
$dbh->disconnect;

print<<EOD;
Content-Type: text/html
Status: 301
Location: /cgi-bin/fpa/reconcile.pl?$Acctype

EOD
exit;

sub reverse_txn {

#  Now get the related inv_txn

	$Inv_txns = $dbh->prepare("select * from inv_txns where acct_id='$COOKIE->{ACCT}' and txn_id=$Txn->{id}");
	$Inv_txns->execute;

	if ($Inv_txns->rows > 0) {
		$Inv_txn = $Inv_txns->fetchrow_hashref;

#  Get details of the invoice to be deleted

		$Invoices = $dbh->prepare("select * from invoices where acct_id='$COOKIE->{ACCT}' and id=$Inv_txn->{inv_id}");
		$Invoices->execute;
		$Invoice = $Invoices->fetchrow_hashref;

		$Inv_total = $Invoice->{invtotal} + $Invoice->{invvat} - $Invoice->{invpaid} - $Invoice->{invpaidvat};

		if ($Invoice->{invtype} =~ /P/i) {		#  Only interested in Purchase invoices

#  Decrement all higher Purchase Invoice nos

			$Sts = $dbh->do("update invoices set invinvoiceno=cast(invinvoiceno as unsigned)-1 where acct_id='$COOKIE->{ACCT}' and invtype='P' and cast(invinvoiceno as unsigned) > $Invoice->{invinvoiceno}");

#  Decrement the comnextpi

			$Sts = $dbh->do("update companies set comnextpi=cast(comnextpi as unsigned) - 1 where reg_id=$Reg_id and id=$Com_id");

#  Find nominals for this invoice

			$Nominals = $dbh->prepare("select * from nominals where acct_id='$COOKIE->{ACCT}' and nomtype='S' and link_id=$Invoice->{id}");
			$Nominals->execute;
			while ($Nominal = $Nominals->fetchrow_hashref) {

#  Subtract amount from the relevant coa

				$Sts = $dbh->do("update coas set coabalance=coabalance-'$Nominal->{nomamount}' where acct_id='$COOKIE->{ACCT}' and coanominalcode='$Nominal->{nomcode}'");

#  Delete the nominalcode

				$Sts = $dbh->do("delete from nominals where acct_id='$COOKIE->{ACCT}' and id=$Nominal->{id}");
			}

#  Delete the invoice

			$Sts = $dbh->do("delete from invoices where acct_id='$COOKIE->{ACCT}' and id=$Inv_txn->{inv_id}");
			$Invoices->finish;

#  Delete any Invoice Items

			$Sts = $dbh->do("delete from items where acct_id='$COOKIE->{ACCT}' and inv_id=$Invoice->{id}");

#  Write an audit trail comment

			$Sts = $dbh->do("insert into audit_trails (acct_id,link_id,audtype,audaction,audtext,auduser) values ('$COOKIE->{ACCT}',$Invoice->{id},'reverse_txns.pl','adj','$Invoice->{invinvoiceno} deleted','$COOKIE->{USER}')");
		}

#  Adjust any cusbalance

		$Sts = $dbh->do("update customers set cusbalance=cusbalance-'$Inv_total' where acct_id='$COOKIE->{ACCT}' and id=$Invoice->{cus_id}");

#  Delete inv_txns

		$Sts = $dbh->do("delete from inv_txns where acct_id='$COOKIE->{ACCT}' and id=$Inv_txn->{id}");
	}
	$Inv_txns->finish;

#  Delete the transaction

	$Sts = $dbh->do("delete from transactions where acct_id='$COOKIE->{ACCT}' and id=$Txn->{id}");
	$Txns->finish;

#  If this is a VAT transaction then revert the VAT Return to 'Filed'

	if ($Txn->{txntxntype} =~ /vat/i) {
		$Sts = $dbh->do("update vatreturns set perstatus='Filed' where acct_id='$COOKIE->{ACCT}' and id=$Txn->{link_id}");
	}

#  Write an audit trail comment

	$Sts = $dbh->do("insert into audit_trails (acct_id,link_id,audtype,audaction,audtext,auduser) values ('$COOKIE->{ACCT}',$Txn->{id},'reverse_txns.pl','adj','$Txn->{txncusname} ($Txn->{txnremarks}) deleted','$COOKIE->{USER}')");

#  Decrement all higher Transaction nos

	$Sts = $dbh->do("update transactions set txntxnno=cast(txntxnno as unsigned)-1 where acct_id='$COOKIE->{ACCT}' and cast(txntxnno as unsigned) > $Txn->{txntxnno}");

#  Decrement the comnexttxn

	$Sts = $dbh->do("update companies set comnexttxn=cast(comnexttxn as unsigned) - 1 where reg_id=$Reg_id and id=$Com_id");

#  Finally delete the transaction nominal codes and adjust the coa

#  Find nominals for this transaction

	$Nominals = $dbh->prepare("select * from nominals where acct_id='$COOKIE->{ACCT}' and nomtype='T' and link_id=$Txn->{id}");
	$Nominals->execute;
	while ($Nominal = $Nominals->fetchrow_hashref) {

#  Subtract amount from the relevant coa

		$Sts = $dbh->do("update coas set coabalance=coabalance-'$Nominal->{nomamount}' where acct_id='$COOKIE->{ACCT}' and coanominalcode='$Nominal->{nomcode}'");

#  Delete the nominalcode

		$Sts = $dbh->do("delete from nominals where acct_id='$COOKIE->{ACCT}' and id=$Nominal->{id}");
	}
}
