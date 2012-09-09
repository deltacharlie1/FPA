#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to display P & L accounts for Year End Cleardown

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");
unless ($COOKIE->{NO_ADS}) {
	require "/usr/local/git/fpa/cgi/display_adverts.ph";
	&display_adverts();
}


#  Calculate the year start and year end of the previous FY

($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});

$Dates = $dbh->prepare("select date_sub(comyearend,interval 1 year) as tbend,date_sub(date_add(comyearend, interval 1 day), interval 2 year) as tbstart,date_format(date_sub(comyearend,interval 1 year),'%d %M %Y') as dispend,date_format(date_sub(date_add(comyearend, interval 1 day), interval 2 year),'%d %M %Y') as dispstart,date_format(date_sub(comyearend,interval 1 year),'%d-%b-%y') as repend,date_format(date_sub(date_add(comyearend, interval 1 day), interval 2 year),'%d-%b-%y') as repstart from companies where reg_id=$Reg_id and id=$Com_id");
$Dates->execute;
$Date = $Dates->fetchrow_hashref;
$Dates->finish;
$Date->{tbstart} = '2011-07-01';
$Date->{tbend} = '2012-06-30';
$Date->{fystart} = '2012-07-01';
$Date->{dispstart} = '01-Jul-11';
$Date->{dispend} = '30-Jun-12';

$Coas = $dbh->prepare("select coas.coanominalcode as nominalcode,coadesc,coatype,sum(nominals.nomamount) as balance from coas left join nominals on (nominals.nomcode=coas.coanominalcode and nominals.acct_id=coas.acct_id) where nominals.nomdate>='$Date->{tbstart}' and nominals.nomdate<='$Date->{tbend}' and coanominalcode>'3999' and coas.acct_id='$COOKIE->{ACCT}' group by nominals.nomcode order by nominals.nomcode");
$Coas->execute;
$Coa = $Coas->fetchall_arrayref({});

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
        WRAPPER => 'header.tt',
});

$Vars = {
	 ads => $Adverts,
        title => 'Accounts - Coas',
	cookie => $COOKIE,
	repdate => $Date,
	entries => $Coa
};

print "Content-Type: text/html\n\n";
$tt->process('yearend_cleardown.tt',$Vars);

$Coas->finish;
$dbh->disconnect;
exit;

