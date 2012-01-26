#!/usr/bin/perl

# script to capture pool choices

if ($ENV{QUERY_STRING}) {
	($Email,$Vote,$Poll) = split(/\?/,$ENV{QUERY_STRING});
	use DBI;

	$dbh = DBI->connect("DBI:mysql:fpa");

#  Check that user has not already voted

	$Polls = $dbh->prepare("select * from poll where email='$Email' and poll='$Poll'");
	$Polls->execute;
	
	$Sts = $dbh->do("insert into poll (email,vote,poll) values ('$Email','$Vote','$Poll')");
	$dbh->disconnect;
}
print<<EOD;
Content-Type: text/plain
Status: 202 Accepted

EOD
exit;
