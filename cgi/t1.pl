#!/usr/bin/perl

use DBI;
$dbh = DBI->connect("DBI:mysql:fpa");
$i = $dbh->prepare("select id,compayref,comdougref,reg_id,comdocsdir,comsubref from companies where id=5978");
$i->execute();
while (@i = $i->fetchrow) {
	print "id = $i[0]\npyid = $i[1]\ndoug = $i[2]\nreg id = $i[3]\n";
}
$i->finish;
$dbh->disconnect;
exit;

