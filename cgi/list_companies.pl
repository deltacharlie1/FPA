#!/usr/bin/perl

$ACCESS_LEVEL = 5;

#  script to list managed companies, ie those with the same reg_id as the user

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");
unless ($COOKIE->{NO_ADS}) {
	require "/usr/local/git/fpa/cgi/display_adverts.ph";
	&display_adverts();
}

($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});

$Companies = $dbh->prepare("select distinct companies.id,companies.reg_id,companies.comname,comcontact,comemail,date_format(comyearend,'%b') as comyearend,comvatscheme,comvatduein,comcis from companies left join reg_coms on (companies.id=com_id)  where (reg_coms.reg1_id=$Reg_id or reg_coms.reg2_id=$Reg_id) order by comname");
$Companies->execute;

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
        WRAPPER => 'header.tt',
});

$Vars = {
        title => 'List Companies',
	cookie => $COOKIE,
	companies => $Companies->fetchall_arrayref({})
};

print "Content-Type: text/html\n\n";
$tt->process('list_companies.tt',$Vars);

$Companies->finish;
$dbh->disconnect;
exit;

