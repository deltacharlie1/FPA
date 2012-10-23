#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to display  existing invoice template

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");

$Invoices = $dbh->prepare("select id,cus_id,invcusname,invtype,invcuscontact,invcusemail,invlayout from invoice_templates where acct_id='$COOKIE->{ACCT}' and id=$ENV{QUERY_STRING}");
$Invoices->execute;
$Invoice = $Invoices->fetchrow_hashref;

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
        WRAPPER => 'header.tt',
});

$Vars = {
	 ads => $Adverts,
        title => 'Invoice Templates',
	cookie => $COOKIE,
	invoice => $Invoice
};

print "Content-Type: text/html\n\n";
$tt->process('preview_invoice_template.tt',$Vars);

$Invoices->finish;
$dbh->disconnect;
exit;

