#!/usr/bin/perl

#  Script to delete nominal ledger entries for voided and cancelled invoices

use DBI;

$Cnt = 0;
$dbh = DBI->connect("DBI:mysql:fpa");

$Invoices = $dbh->prepare("select acct_id,id from invoices where invstatus in ('VOIDED','CANCELLED')");
$Invoices->execute;
print "No of invoices = ".$Invoices->rows."\n\n";

while ($Invoice = $Invoices->fetchrow_hashref) {
	$Sts = $dbh->do("delete from nominals where nomtype='S' and acct_id='$Invoice->{acct_id}' and link_id=$Invoice->{id}");
	$Cnt += $Sts;
}
$Invoices->finish;
$dbh->disconnect;
print "$Cnt records deleted\n";
exit;
