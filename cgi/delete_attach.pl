#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to delete attachments

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

use CGI;
use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");
($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});

$Data = CGI->new();
$Id = $Data->param('id');

$Sts = $dbh->do("delete from images where id=$Id and acct_id='$COOKIE->{ACCT}'");
$dbh->disconnect;
print<<EOD;
Content-Type: text/plain
Status: 200 OK

EOD
exit;
