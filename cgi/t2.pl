#!/usr/bin/perl

$Dte = `date +%d-%m-%Y:%H:%M:%S:000`;
chomp($Dte);

$Dte =~ s/:.*//;
print "$Dte\n";
exit;

use DBI;
$dbh = DBI->connect("DBI:mysql:fpa");

$Noms = $dbh->prepare("select link_id,nomtype,nomcode,nomamount from nominals where acct_id='1+1' and nomcode='6000' order by nomdate desc");
$Noms->execute;

print "No of rows = ".$Noms->rows."\n\n";

$Nomm = $Noms->fetchall_arrayref({});
$Noms->finish;

foreach $Nom (@$Nomm) {
	print $Nom->{nomtype}."\t".$Nom->{nomcode}."\t".$Nom->{nomamount}."\n";
}

$dbh->disconnect;
exit;
