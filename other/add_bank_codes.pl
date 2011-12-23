#!/usr/bin/perl

use DBI;
$dbh = DBI->connect("DBI:mysql:fpa");

$Coas = $dbh->prepare("select distinct acct_id from coas");
$Coas->execute;
while (@Coa = $Coas->fetchrow) {
	$Sts = $dbh->do("insert into coas (acct_id,coanominalcode,coadesc,coatype,coagroup,coareport) values ('$Coa[0]','4310','Bank Interest','Income','4300','P & L')");
	$Sts = $dbh->do("insert into coas (acct_id,coanominalcode,coadesc,coatype,coagroup,coareport) values ('$Coa[0]','6010','Bank Charges','Expenses','6000','P & L')");
}
$Coas->finish;
$dbh->disconnect;
exit;
