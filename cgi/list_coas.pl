#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to display Chart of Account details

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

use DBI;
my $dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");

$Coas = $dbh->prepare("select coanominalcode,coadesc,coatype,coabalance from coas where acct_id=? order by coanominalcode");
$Coas->execute("$COOKIE->{ACCT}");

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
        WRAPPER => 'header.tt',
});

$Vars = {
        title => 'Accounts - Coas',
	cookie => $COOKIE,
	entries => $Coas->fetchall_arrayref({})
};

print "Content-Type: text/html\n\n";
$tt->process('list_coas.tt',$Vars);

$Coas->finish;
$dbh->disconnect;
exit;

