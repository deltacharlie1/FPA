#!/usr/bin/perl

use DBI;
$dbh = DBI->connect("DBI:mysql:fpa");
$Sales = $dbh->prepare("select sum(invtotal) as tot,date_format(invprintdate,'%m') as printdate from invoices where invtype in ('S','C') and invstatuscode>'1' and acct_id='1+1' and invprintdate > date_sub(now(),interval 1 year) group by printdate order by invprintdate");
$Sales->execute;
$Sale = $Sales->fetchrow_hashref;
while (($Key,$Value) = each %$Sale) {
	print "$Key => $Value\n";
}
$Sales->finish;
$dbh->disconnect;
exit;
