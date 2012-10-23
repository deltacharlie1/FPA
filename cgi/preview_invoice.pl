#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to display  existing invoices

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");
($Id,$Tplt) = split(/\?/,$ENV{QUERY_STRING});

$Invoices = $dbh->prepare("select id,cus_id,invinvoiceno,invcusname,invtype,invcuscontact,invcusemail,invstatuscode,invlayout from invoice${Tplt}s where acct_id='$COOKIE->{ACCT}' and id=$Id");
$Invoices->execute;
$Invoice = $Invoices->fetchrow_hashref;

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
        WRAPPER => 'header.tt',
});

$Vars = {
        title => 'Preview Invoice',
	tplt => $Tplt,
	cookie => $COOKIE,
	invoice => $Invoice
};

print "Content-Type: text/html\n\n";
$tt->process('preview_invoice.tt',$Vars);

$Invoices->finish;
$dbh->disconnect;
exit;

