#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to reconcile an account

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

$Acctype = $ENV{QUERY_STRING};

$Acctype = $Acctype || "1200";

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");
unless ($COOKIE->{NO_ADS}) {
	require "/usr/local/git/fpa/cgi/display_adverts.ph";
	&display_adverts();
}


$Accts = $dbh->prepare("select accounts.id,accounts.acctype,accname,accacctno,stastmtno,staclosebal,date_format(staclosedate,'%d-%b-%y') as staclosedate from accounts left join statements on (accounts.id=acc_id) where accounts.acct_id='$COOKIE->{ACCT}' and acctype='$Acctype' order by statements.id desc limit 1");
$Accts->execute;
$Acct = $Accts->fetchrow_hashref;
$Accts->finish;

$TSs = $dbh->prepare("select f1,f2,f3 from tempstacks where acct_id='$COOKIE->{ACCT}' and caller='reconciliation'");
$TSs->execute;
$TS = $TSs->fetchrow_hashref;
$TSs->finish;

use Template;
$tt = Template->new({
       	INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
        WRAPPER => 'header.tt',
});

$Vars = {
       	title => 'Accounts - Reconciliations',
	cookie => $COOKIE,
	acct => $Acct,
	ts => $TS,
	focus => 'stmt',
	javascript => '<script type="text/javascript">
var errfocus;
function validate_stmt() {
  var errs = "";
  if (! /^\d+$/.test(document.getElementById("stmtno").value)) {
    errs = errs + "<li>You must enter a valid statement number</li>";
    errfocus = "stmtno";
  }
  if (document.getElementById("stmt").value.length < 10) {
    errs = errs + "<li>You must paste in a statement</li>";
    errfocus = "stmt";
  }
  if (errs.length > 0) {
    document.getElementById("dialog").innerHTML = "You have the following errors:-<ol>"+errs+"</ol>";
    $("#dialog").dialog("open");
    return false;
  }
}
</script>'
};

print "Content-Type: text/html\n\n";
$tt->process('newrec.tt',$Vars);

$dbh->disconnect;
exit;

