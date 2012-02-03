#!/usr/bin/perl
use Digest;
use DBI;
$dbh = DBI->connect("DBI:mysql:fpa");
$Registrations = $dbh->prepare("select regemail from registrations");
$Registrations->execute;
while ($Registration = $Registrations->fetchrow_hashref) {

	$Hash = Digest->new("MD5");
	$Hash->add($Registration->{regemail});
	$Hash_hex = $Hash->hexdigest;
	$FORM{$Hash_hex}++;
}

foreach $Key (sort keys %FORM) {
	print "$Key\t$FORM{$Key}\n";
}
$Registrations->finish;
$dbh->disconnect;
exit;
