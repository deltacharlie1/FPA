#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  Script to create an invoice PDF file

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

$Invoice_id = $ENV{QUERY_STRING};

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");
($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});

$Subs = $dbh->prepare("select subinvoiceno,date_format(subdateraised,'%D %M %Y'),subauthcode,concat(comaddress,'  ',compostcode),subdescription,subnet,subvat,substatus,date_format(subdatepaid,'%D %M %Y') from subscriptions,companies where acct_id='$COOKIE->{ACCT}' and companies.id=$Com_id and reg_id=$Reg_id");
$Subs->execute;
($Inv_invoice_no,$Inv_date,$Inv_authcode,$Inv_address,$Inv_desc,$Inv_net,$Inv_vat,$Inv_status,$Inv_datepaid) = $Subs->fetchrow;
$Subs->finish;
$Inv_type = "INVOICE";

require "/usr/local/httpd/cgi-bin/fpa/pdf_sub_invoice.ph";
($PDF_data) = &pdf_invoice();

print "Content-Type: application/pdf\n";
print "Content-Disposition: inline; filename=invoice_$Inv_invoice_no.pdf\n\n";
print $PDF_data;

$dbh->disconnect;
exit;

