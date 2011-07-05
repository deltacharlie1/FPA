#!/usr/bin/perl

#  Script to run through all COAs and align totals with the totals in nominals

use DBI;

$dbh = DBI->connect("DBI:mysql:fpa");

$Noms = $dbh->prepare("select sum(nomamount) from nominals where acct_id=? and nomcode=?");

$COAs = $dbh->prepare("select id,acct_id,coanominalcode from coas");
$COAs->execute;
while (@COA = $COAs->fetchrow) {
	$Noms->execute("$COA[1]","$COA[2]");
	($Sum) = $Noms->fetchrow;

	$Sts = $dbh->do("update coas set coabalance='$Sum' where id=$COA[0]");
}
$Noms->finish;
$COAs->finish;
exit;
