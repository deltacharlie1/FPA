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

($Inv_id,$Action) = split(/\?/,$ENV{QUERY_STRING});

$Invoices = $dbh->prepare("select id,cus_id,invinvoiceno,invcusname,invtype,invcuscontact,invcusemail,invstatuscode from invoices where id=? and acct_id=?");
$Invoices->execute($Inv_id,"$COOKIE->{ACCT}");
$Invoice = $Invoices->fetchrow_hashref;
$Invoice->{action} = $Action;

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
        WRAPPER => 'header.tt',
});

$Vars = {
        title => 'Accounts - Suppliers',
	cookie => $COOKIE,
	invoice => $Invoice
};

print "Content-Type: text/html\n\n";
$tt->process('preview_purchase.tt',$Vars);

$Invoices->finish;
$dbh->disconnect;
exit;

