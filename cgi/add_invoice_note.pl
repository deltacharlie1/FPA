#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to add a note to an invoice

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

use CGI;
use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");
#
$Data = new CGI;
%FORM = $Data->Vars;

$Sts = $dbh->do("update invoices set invnotes='$FORM{invnote}' where id=$FORM{id} and acct_id='$COOKIE->{ACCT}'");
print<<EOD;
Content-Type: text/plain

OK
EOD

$dbh->disconnect;
exit;
