#!/usr/bin/perl

$ACCESS_LEVEL = 3;

#  script to display Transaction details

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");
$Journals = $dbh->prepare("select joujnlno,joudesc,date_format(joudate,'%d-%b-%y') as jnldate from journals where acct_id='$COOKIE->{ACCT}' and id=$ENV{QUERY_STRING}");
$Journals->execute;
$Journal = $Journals->fetchrow_hashref;
$Journals->finish;

$Nominals = $dbh->prepare("select nomcode,coadesc,nomamount,coatype from nominals left join coas on (nomcode=coanominalcode and nominals.acct_id=coas.acct_id) where nominals.acct_id='$COOKIE->{ACCT}' and journal_id=$ENV{QUERY_STRING} order by nominals.id");
$Nominals->execute;
$Nominal = $Nominals->fetchall_arrayref({});
$Nominals->finish;

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
        WRAPPER => 'header.tt',
});

$Vars = {
	 ads => $Adverts,
       	title => 'Journal Detail',
	cookie => $COOKIE,
	jnl => $Journal,
	entries => $Nominal
};

$Nominals->finish;
print "Content-Type: text/html\n\n";
$tt->process('jnl_drill_down.tt',$Vars);

$dbh->disconnect;
exit;

