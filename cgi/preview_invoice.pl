#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to display  existing invoices

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");
unless ($COOKIE->{NO_ADS}) {
	require "/usr/local/git/fpa/cgi/display_adverts.ph";
	&display_adverts();
}


$Invoices = $dbh->prepare("select id,cus_id,invinvoiceno,invcusname,invtype,invcuscontact,invcusemail,invstatuscode,invlayout from invoices where id=? and acct_id=?");
$Invoices->execute($ENV{QUERY_STRING},"$COOKIE->{ACCT}");
$Invoice = $Invoices->fetchrow_hashref;

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
        WRAPPER => 'header.tt',
});

$Vars = {
	 ads => $Adverts,
        title => 'Accounts - Customers',
	cookie => $COOKIE,
	invoice => $Invoice
};

print "Content-Type: text/html\n\n";
$tt->process('preview_invoice.tt',$Vars);

$Invoices->finish;
$dbh->disconnect;
exit;

