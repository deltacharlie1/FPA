#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to wipe clean a user's account

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

use CGI;
use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");

$Data = new CGI;
%FORM = $Data->Vars;

while (( $Key,$Value) = each %FORM) {

#  Remove any bad characters

	$Value =~ tr/\\//d;
	$Value =~ s/\'/\\\'/g;
	$FORM{$Key} = $Value;
}

($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});

$Errs = "";

#  Check the password

if ($FORM{regpwd}) {

	$Regs = $dbh->prepare("select * from registrations where regpwd=password('$FORM{regpwd}') and reg_id=$Reg_id");
	$Regs->execute;
	if ($Regs->rows < 1) {
		$Errs .= "<li>You have entered an incorrect password</li>\n";
	}
	$Regs->finish;
}
else {
	$Errs .= "<li>You have not entered your password</li>\n";
}

if ($Errs) {
	print<<EOD;
Content-Type: text/plain

You have the following error:-<ol>$Errs</ol>Please correct if you wish to proceed
EOD
}
else {

	$Sts = $dbh->do("delete from invoices where acct_id='$COOKIE->{ACCT}'");
	$Sts = $dbh->do("delete from transactions where acct_id='$COOKIE->{ACCT}'");
	$Sts = $dbh->do("delete from inv_txns where acct_id='$COOKIE->{ACCT}'");
	$Sts = $dbh->do("delete from audit_trails where acct_id='$COOKIE->{ACCT}'");
	$Sts = $dbh->do("delete from statements where acct_id='$COOKIE->{ACCT}'");
	$Sts = $dbh->do("delete from vatreturns where acct_id='$COOKIE->{ACCT}'");
	$Sts = $dbh->do("delete from vataccruals where acct_id='$COOKIE->{ACCT}'");
	$Sts = $dbh->do("delete from reminders where acct_id='$COOKIE->{ACCT}'");
	$Sts = $dbh->do("delete from nominals where acct_id='$COOKIE->{ACCT}'");
	$Sts = $dbh->do("delete from items where acct_id='$COOKIE->{ACCT}'");

	if ($FORM{rem2} =~ /Y/) {
		$Sts = $dbh->do("delete from customers where acct_id='$COOKIE->{ACCT}'");
	}
	else {
		$Sts = $dbh->do("update customers set cusbalance='0',cuscredit='0',cuslimit='0',cusremarks='' where acct_id='$COOKIE->{ACCT}'");
	}

	$Sts = $dbh->do("update coas set coabalance='0' where acct_id='$COOKIE->{ACCT}'");
	$Sts = $dbh->do("update companies set comvatcontrol='0',comnextsi='100001',comnextpi='500001',comnocheques='0',comacccompleted='N',comnexttxn='1' where reg_id=$Reg_id and id=$Com_id");
	print<<EOD;
Content-Type: text/plain

OK-Your data has been permanently deleted
EOD
}
$dbh->disconnect;
exit;
