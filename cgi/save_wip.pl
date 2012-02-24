#!/usr/bin/perl

#  script to save reconciliation work in progress
#
$ACCESS_LEVEL = 1;

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

read(STDIN, $Buffer, $ENV{'CONTENT_LENGTH'});
@pairs = split(/&/,$Buffer);

foreach $pair (@pairs) {

        ($Name, $Value) = split(/=/, $pair);

        $FORM{$Name} = $Value;
}

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");

$Sts = $dbh->do("update tempstacks set f3='$FORM{data}' where acct_id='$COOKIE->{ACCT}' and caller='reconciliation'");
$dbh->disconnect;
exit;
