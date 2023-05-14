#!/usr/bin/perl

#  Script to run through all COAs and align totals with the totals in nominals

use DBI;

$dbh = DBI->connect("DBI:mysql:fpa");
while(<>) {
	&upd_tables();
}
 $Invtxns->finish;
$dbh->disconnect;
exit;

sub upd_tables {
	($inv,$dte) = split(",",$_);
	chomp($dte);
	$dte =~ s/(\d\d)\/(\d\d)\/(\d\d)/20$3-$2-$1/;

	print "$inv\t$dte\n";

	$Invtxns = $dbh->prepare("select txn_id from inv_txns where acct_id='6126+6139' and itinvoiceno='$inv'");
	$Invtxns->execute;
	@Invtxn = $Invtxns->fetchrow;

	$dbh->do("update invoices set invprintdate='$dte',invduedate='$dte',invpaiddate='$dte' where acct_id='6126+6139' and invinvoiceno='$inv'");
	$dbh->do("update inv_txns set itdate='$dte' where acct_id='6126+6139' and itinvoiceno='$inv'");
	$dbh->do("update transactions set txndate='$dte' where acct_id='6126+6139' and id=$Invtxn[0]");
}
