#!/usr/bin/perl

# script to capture pool choices

if ($ENV{QUERY_STRING}) {
	($Email,$Vote) = split(/\?/,$ENV{QUERY_STRING});
	use DBI;

	$dbh = DBI->connect("DBI:mysql:fpa");
	$Sts = $dbh->do("insert into poll (email,vote) values ('$Email','$Vote')");
	$dbh->disconnect;
}
print<<EOD;
Content-Type: text/plain
Status: 204 No Content

EOD
exit;
