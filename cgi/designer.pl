#!/usr/bin/perl

#  The default initial menu displayed at first login

$ACCESS_LEVEL = 0;

# use Checkid;

use Checkid;
$COOKIE =  &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

use DBI;
my $dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");

($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});

$Invoices = $dbh->prepare("select id as invid,invinvoiceno,invcusname,(invtotal+invvat - invpaid - invpaidvat) as invamount from invoices where invtype='S' and invstatuscode > 6 and acct_id=? order by invprintdate");
$Invoices->execute("$COOKIE->{ACCT}");

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib']
});

$Vars = {
        title => 'Accounts - Main Screen',
	cookie => $COOKIE,
        invoices => $Invoices->fetchall_arrayref({}),
	coa => $Coa,
	company => $Company,
	reminders => $Reminder
};


print "Content-Type: text/html\n";
print "Set-Cookie: fpa-comname=$Company->{comname}; path=/;\n\n";

$tt->process('testit.tt',$Vars);
$dbh->disconnect;
exit;

