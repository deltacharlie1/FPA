#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  Script to create an invoice template PDF file

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

($Invoice_id,$Layout_id,$Testonly) = split(/\?/,$ENV{QUERY_STRING});

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");
if ($Layout_id > 0) {
	require "/usr/local/httpd/cgi-bin/fpa/pdf_layout.ph";
}
else {
	require "/usr/local/httpd/cgi-bin/fpa/pdf_invoice.ph";
}
($PDF_data,$Invoice_no) = &pdf_invoice($Invoice_id,'Y',$Layout_id,$Testonly,'_template');

print "Content-Type: application/pdf\n";
print "Content-Disposition: inline; filename=invoice_$Invoice_no.pdf\n\n";
print $PDF_data;

$dbh->disconnect;
exit;

