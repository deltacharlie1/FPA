#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  Script to create an invoice PDF file

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

($Invoice_id,$Action) = split(/\?/,$ENV{QUERY_STRING});

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");
unless ($COOKIE->{NO_ADS}) {
	require "/usr/local/git/fpa/cgi/display_adverts.ph";
	&display_adverts();
}


require "/usr/local/httpd/cgi-bin/fpa/pdf_purchase.ph";
($PDF_data,$Invoice_no) = &pdf_invoice($Invoice_id,$Action);

print "Content-Type: application/pdf\n";
print "Content-Disposition: inline; filename=invoice_$Invoice_no.pdf\n\n";
print $PDF_data;

$dbh->disconnect;
exit;

