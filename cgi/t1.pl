#!/usr/bin/perl

use DBI;
$dbh = DBI->connect("DBI:mysql:fpa");
$TSs = $dbh->prepare("select acct_id from tempstacks");
$TSs->execute;
while ($TS = $TSs->fetchrow_hashref) {
	$Sts = $dbh->do("insert into tempstacks (acct_id,caller) values ('$TS->{acct_id}','trial_balance')");
	$Sts = $dbh->do("insert into tempstacks (acct_id,caller) values ('$TS->{acct_id}','pandl')");
}
$TSs->finish;
$dbh->disconnect;
exit;
