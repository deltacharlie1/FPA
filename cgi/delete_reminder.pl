#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to delete a reminder

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");
unless ($COOKIE->{NO_ADS}) {
	require "/usr/local/git/fpa/cgi/display_adverts.ph";
	&display_adverts();
}


#  Then just delete the record

$Sts = $dbh->do("delete from reminders where acct_id='$COOKIE->{ACCT}' and id=$ENV{QUERY_STRING}");

print<<EOD;
Content-Type: text/plain

OK
EOD
$dbh->disconnect;
exit;
