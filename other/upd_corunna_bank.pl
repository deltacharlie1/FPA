#!/usr/bin/perl

#  Script to reset bank charges/interest from 6000/4300 to 6010/4300

use DBI;
$dbh = DBI->connect("DBI:mysql:fpa");

$Txns = $dbh->prepare("select transactions.id,nominals.id,transactions.acct_id,txncusname,txnamount,txnmethod,nomcode,nomamount,nomdate from transactions left join nominals on (transactions.id=nominals.link_id and transactions.acct_id=nominals.acct_id) where transactions.acct_id='1+1' and txncusname like 'Bank Pa%' and nomcode='6000' and nomdate>'2011-06-30' order by nomdate");
$Txns->execute;
while (@Txn = $Txns->fetchrow) {
	$Sum += $Txn[7];
	$Sts = $dbh->do("update nominals set nomcode='6010' where id=$Txn[1]");
}
$Sts = $dbh->do("update coas set coabalance=coabalance-'$Sum' where coanominalcode='6000' and acct_id='1+1'");
$Sts = $dbh->do("update coas set coabalance=coabalance+'$Sum' where coanominalcode='6010' and acct_id='1+1'");

$Sum = 0;

$Txns = $dbh->prepare("select transactions.id,nominals.id,transactions.acct_id,txncusname,txnamount,txnmethod,nomcode,nomamount,nomdate from transactions left join nominals on (transactions.id=nominals.link_id and transactions.acct_id=nominals.acct_id) where transactions.acct_id='1+1' and txncusname like 'Bank Pa%' and nomcode='4300' and nomdate>'2011-06-30' order by nomdate");
$Txns->execute;
while (@Txn = $Txns->fetchrow) {
	$Sum += $Txn[7];
	$Sts = $dbh->do("update nominals set nomcode='4310' where id=$Txn[1]");
}
$Sts = $dbh->do("update coas set coabalance=coabalance-'$Sum' where coanominalcode='4300' and acct_id='1+1'");
$Sts = $dbh->do("update coas set coabalance=coabalance+'$Sum' where coanominalcode='4310' and acct_id='1+1'");

$Txns->finish;
$dbh->disconnect;
exit;
