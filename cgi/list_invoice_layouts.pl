#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to display invoice layouts

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");
unless ($COOKIE->{NO_ADS}) {
	require "/usr/local/git/fpa/cgi/display_adverts.ph";
	&display_adverts();
}


$Lays = $dbh->prepare("select id,laydesc,layfile from invoice_layouts where acct_id='$COOKIE->{ACCT}'");
$Lays->execute;

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
        WRAPPER => 'header.tt',
});

$Vars = {
	 ads => $Adverts,
        title => 'Invoice Layouts',
	cookie => $COOKIE,
	entries => $Lays->fetchall_arrayref({})
};

print "Content-Type: text/html\n\n";
$tt->process('list_invoice_layouts.tt',$Vars);

$Lays->finish;
$dbh->disconnect;
exit;

