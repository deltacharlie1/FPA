#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to cancel an existing, Final, invoice

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

use CGI;
use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");
#  Get the layout file so that we can delete it

$Layouts = $dbh->prepare("select layfile from invoice_layouts where acct_id='$COOKIE->{ACCT}' and id=$ENV{QUERY_STRING}");
$Layouts->execute;
$Layout = $Layouts->fetchrow_hashref;
$Layouts->finish;

unlink($Layout->{layfile});

$Sts = $dbh->do("delete from invoice_layouts where acct_id='$COOKIE->{ACCT}' and id=$ENV{QUERY_STRING}");
$Sts = $dbh->do("delete from invoice_layout_items where acct_id='$COOKIE->{ACCT}' and link_id=$ENV{QUERY_STRING}");

$dbh->disconnect;
print<<EOD;
Content-Type: text/html
Status: 302
Location: /cgi-bin/fpa/list_invoice_layouts.pl

EOD
exit;
