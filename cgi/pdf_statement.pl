#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  Script to create a statement PDF file

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");

require "/usr/local/httpd/cgi-bin/fpa/pdf_statement.ph";
($PDF_data,$Date) = &pdf_statement($ENV{QUERY_STRING});

print "Content-Type: application/pdf\n";
print "Content-Disposition: inline; filename=$Date_statement.pdf\n\n";
print $PDF_data;

$dbh->disconnect;
exit;

