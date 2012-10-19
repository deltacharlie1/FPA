#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to reconcile a statement

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

use CGI;
use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");

$Data = new CGI;
%FORM = $Data->Vars;

# print "Content-Type: text/plain\n\n";

while (( $Key,$Value) = each %FORM) {

#  Remove any bad characters

	$Value =~ tr/\\//d;
	$Value =~ s/\'/\\\'/g;
        $FORM{$Key} = $Value;

}

#  get number of transactions involved

$Txns = $dbh->prepare("select count(*) from transactions where acct_id='$COOKIE->{ACCT}' and txnmethod='$FORM{txnmethod}' and txnselected='P'");
$Txns->execute;
($Txn_count) = $Txns->fetchrow;
$Txns->finish;

#  Get the last statement no

$Stmts = $dbh->prepare("select stastmtno,starec_no from statements left join accounts on (acc_id=accounts.id) where statements.acct_id='$COOKIE->{ACCT}' and acctype='$FORM{txnmethod}' order by staclosedate desc limit 1");
$Stmts->execute;
@Stmt = $Stmts->fetchrow;
$Stmts->finish;

#  Do some basic validation

$Errs = "";

# if ($Company[0] =~ /Y/i) {
#	$Errs .= "<li>Opening balances have already been entered and cannot be re-entered.</li>\n"; 
#}
#else {
if ($FORM{thisno} !~ /^-?\d+\.?\d?\d?$/) {
	$Errs .= "<li>Invalid Statement Number</li>\n";
}
else {
	if ($Stmt[0] >= $FORM{thisno}) {
		$Errs .= "<li>This statement has already been reconciled</li>\n";
	}
}
if ($FORM{thiscf} !~ /^-?\d+\.?\d?\d?$/) { $Errs .= "<li>Invalid Carried Forward amount</li>\n"; }
if ($Txn_count < 1) { $Errs .= "<li>No transactions left to be reconciled</li>\n"; }
#}

if ($Errs) {
	print<<EOD;
Content-Type: text/plain

Errors!

You have the following errors:-
<ol>$Errs</ol>
Please correct them and re-submit
EOD
}
else {

#  get no of transactions on statement (count the Ps)
#  get the account name from coas
#  create statement record
#  update the transactions from P to F to freeze them (and get the count)
#  clear out tempstacks
#  add audit trail record

#  Get the account name

	$Coas = $dbh->prepare("select coadesc from coas where acct_id='$COOKIE->{ACCT}' and coanominalcode='$FORM{txnmethod}'");
	$Coas->execute;
	($Accname) = $Coas->fetchrow;
	$Coas->finish;

#  create the statement record

	if ($FORM{thiscfdate}) {
		$Stmt_date = "str_to_date('$FORM{thiscfdate}','%d-%b-%y')";
	}
	else {
		$Stmt_date = "now()";
	}
	$Stmt[1]++;		#  Increment the reconciliation count no

	$Sts = $dbh->do("insert into statements (acct_id,acc_id,staopenbal,staclosebal,stastmtno,staopendate,staclosedate,stanotxns,starec_no) values ('$COOKIE->{ACCT}',$FORM{id},'$FORM{thatbf}','$FORM{thiscf}','$FORM{thisno}',str_to_date('$FORM{staopendate}','%d-%b-%y'),$Stmt_date,'$Txn_count',$Stmt[1])");
        $New_stmt_id = $dbh->last_insert_id(undef, undef, qw(transactionss undef));

#  update the relevant transactions

	$Sts = $dbh->do("update transactions set txnselected='F',stmt_id=$New_stmt_id where acct_id='$COOKIE->{ACCT}' and txnmethod='$FORM{txnmethod}' and txnselected='P'");

#  clear out the tempstacks record

	$Sts = $dbh->do("update tempstacks set f1='',f2='',f3='',f4='',f5='',f6='' where acct_id='$COOKIE->{ACCT}' and caller='reconciliation'");

#  finally, add an audit trail record

        $Sts = $dbh->do("insert into audit_trails (acct_id,link_id,audtype,audaction,audtext,auduser) values ('$COOKIE->{ACCT}',$New_stmt_id,'reconcile.pl','reconcile','$Accname statement $FORM{thisno} reconciled with $Txn_count items','$COOKIE->{USER}')");

	print<<EOD;
Content-Type: text/plain

OK-list_stmt_txns.pl?filter=$New_stmt_id

EOD
}
$dbh->disconnect;
exit;
