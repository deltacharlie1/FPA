#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to list Accounts

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");
unless ($COOKIE->{NO_ADS}) {
	require "/usr/local/git/fpa/cgi/display_adverts.ph";
	&display_adverts();
}


$Accts = $dbh->prepare("select accounts.accnewrec,accounts.acctype,accounts.id,coadesc,accounts.accname,accounts.accsort,accounts.accacctno,stastmtno,staclosebal,coabalance from accounts left join (select * from statements where acct_id='$COOKIE->{ACCT}' order by id desc) as statements on (accounts.id=statements.acc_id),accounts a left join coas on (a.acctype=coas.coanominalcode) where accounts.id=a.id and accounts.acct_id='$COOKIE->{ACCT}' and coas.acct_id='$COOKIE->{ACCT}' group by accounts.id order by accounts.acctype");
$Accts->execute;

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
        WRAPPER => 'header.tt',
});

$Vars = {
	 ads => $Adverts,
        title => 'Accounts - Accounts',
	cookie => $COOKIE,
pagetitle => 'List of Accounts',
	entries => $Accts->fetchall_arrayref({})
};

print "Content-Type: text/html\n\n";
$tt->process('list_accounts.tt',$Vars);

$Accts->finish;
$dbh->disconnect;
exit;

