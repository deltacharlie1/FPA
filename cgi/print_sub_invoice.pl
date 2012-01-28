#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to display  existing invoices

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);
($Inv_id,$Inv_no) = split(/\?/,$ENV{QUERY_STRING});

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");
unless ($COOKIE->{NO_ADS}) {
        require "/usr/local/git/fpa/cgi/display_adverts.ph";
        &display_adverts();
}
$dbh->disconnect;

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
        WRAPPER => 'header.tt',
});

$Vars = {
        title => 'Accounts - Subscriptions',
	cookie => $COOKIE,
	invid => $Inv_id,
	invno => $Inv_no
};

print "Content-Type: text/html\n\n";
$tt->process('print_sub_invoice.tt',$Vars);

exit;

