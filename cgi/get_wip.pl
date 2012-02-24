#!/usr/bin/perl

#  script to save reconciliation work in progress
#
$ACCESS_LEVEL = 1;

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");

$TSs = $dbh->prepare("select f3 from tempstacks where acct_id='$COOKIE->{ACCT}' and caller='reconciliation'");
$TSs->execute;
@TS = $TSs->fetchrow;
$TSs->finish;

print<<EOD;
Content-Type: text/plain

$TS[0]
EOD
$dbh->disconnect;
exit;
