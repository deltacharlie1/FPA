#!/usr/bin/perl

print "Content-Type: text/plain\n\n";

use DBI;
$dbh = DBI->connect("DBI:mysql:fpa");
$Companies = $dbh->prepare("select comname,comcontact from companies");
$Companies->execute;
while (@Company = $Companies->fetchrow) {
	print "$Company[0] \t\t-\t$Company[1]\n";
}
$Companies->finish;
$dbh->disconnect;
exit;
