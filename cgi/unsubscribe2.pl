#!/usr/bin/perl

$ACCESS_LEVEL = 0;

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

if ($COOKIE->{BACCT} eq '1+1') {

	$Regs = $dbh->prepare("select reg_id,regusername from registrations where reg_id=$Reg_id");
	$Regs->execute;
	if ($Regs->rows < 1) {
		$Errs .= "<li>This account no longer exists (or cannot be found)</li>\n";
	}
	else {
		@Reg = $Regs->fetchrow;
	}
	$Regs->finish;
}
elsif ($FORM{regpwd}) {

	$Regs = $dbh->prepare("select reg_id,regusername from registrations where regpwd=password('$FORM{regpwd}') and reg_id=$Reg_id");
	$Regs->execute;
	if ($Regs->rows < 1) {
		$Errs .= "<li>You have entered an incorrect password</li>\n";
	}
	else {
		@Reg = $Regs->fetchrow;
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

	
	$Companies = $dbh->prepare("select id,comname,comdocsdir from companies where reg_id=$Reg[0]");
	$Companies->execute;

	while (@Company = $Companies->fetchrow) {

#  remove the docs directory (but first confirm that we are deleting from /projects/fpa_docs :-)

		if ($Company[2] =~ /^\/projects\/fpa_docs\//) {
			`rm -rf $Company[2]`;
		}

#  Construct the acct_id

		$COOKIE->{ACCT} = "$Reg[0]+$Company[0]";

		$Sts = $dbh->do("delete from audit_trails where acct_id='$COOKIE->{ACCT}'");
		$Sts = $dbh->do("delete from accounts where acct_id='$COOKIE->{ACCT}'");
		$Sts = $dbh->do("delete from coas where acct_id='$COOKIE->{ACCT}'");
		$Sts = $dbh->do("delete from customers where acct_id='$COOKIE->{ACCT}'");
		$Sts = $dbh->do("delete from images where acct_id='$COOKIE->{ACCT}'");
		$Sts = $dbh->do("delete from inv_txns where acct_id='$COOKIE->{ACCT}'");
		$Sts = $dbh->do("delete from invoice_templates where acct_id='$COOKIE->{ACCT}'");
		$Sts = $dbh->do("delete from invoices where acct_id='$COOKIE->{ACCT}'");
		$Sts = $dbh->do("delete from items where acct_id='$COOKIE->{ACCT}'");
		$Sts = $dbh->do("delete from nominals where acct_id='$COOKIE->{ACCT}'");
		$Sts = $dbh->do("delete from reminders where acct_id='$COOKIE->{ACCT}'");
		$Sts = $dbh->do("delete from statements where acct_id='$COOKIE->{ACCT}'");
		$Sts = $dbh->do("delete from tempstacks where acct_id='$COOKIE->{ACCT}'");
		$Sts = $dbh->do("delete from transactions where acct_id='$COOKIE->{ACCT}'");
		$Sts = $dbh->do("delete from vataccruals where acct_id='$COOKIE->{ACCT}'");
		$Sts = $dbh->do("delete from vatreturns where acct_id='$COOKIE->{ACCT}'");

#  Delete all additional users

		$Sts = $dbh->do("delete from add_users where addcom_id=$Company[0]");
		$Sts = $dbh->do("delete from reg_coms where com_id=$Company[0]");

#  Then delete the company

		$Sts = $dbh->do("delete from companies where id=$Company[0] and reg_id=$Reg[0]");

	}

#  Finally delete the registration record

	$Sts = $dbh->do("delete from registrations where reg_id=$Reg[0]");

	print<<EOD;
Content-Type: text/plain

OK-Your data has been permanently deleted
EOD
}
$dbh->disconnect;
exit;
