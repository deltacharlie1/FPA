#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to cancel an existing, Final, invoice

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

use CGI;
use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");

$Data = new CGI;
%FORM = $Data->Vars;

($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});

$Invoices = $dbh->prepare("select invtype,cus_id,invcoa,invtotal,invvat,invstatuscode,invinvoiceno from invoices where id=$FORM{id} and acct_id='$COOKIE->{ACCT}'");
$Invoices->execute;
@Invoice = $Invoices->fetchrow;

#  Get the next Sales Invoice # to see whether this is the most recent one

$Companies = $dbh->prepare("select comnextsi from companies where reg_id=$Reg_id and id=$Com_id");
$Companies->execute;
$Company = $Companies->fetchrow_hashref;
$Companies->finish;

$Errs = "";

unless ($Invoice[6] == $Company->{comnextsi}-1) { $Errs .= "<li>This is not the most recent invoice/Credit Note</li>\n"; }
unless ($Invoices->rows > 0) { $Errs .= "<li>Invoice cannot be found</li>\n"; }
if ($Invoice[5] != 3) { $Errs .= "<li>Invoice is not at a stage where it can be deleted</li>\n"; }

if ($Errs) {
	print<<EOD;
Content-Type: text/plain

<ol>Invoice cannot be deleted
$Errs
</ol>
EOD
}
else {

#  Set the total invoice/credit note amount 

	my $Tot = $Invoice[3] + $Invoice[4];
	my $Invoice_type = "Invoice";
	if ($Invtype =~ /C/i) {		#  Credit Note, so reverse amounts
		$Invoice[3] = 0 - $Invoice[3];
		$Invoice[4] = 0 - $Invoice[4];
		$Tot = 0 - $Tot;
		$Invoice_type = "Credit Note";
	}

#  2  write audit trail

	$Sts = $dbh->do("insert into audit_trails (acct_id,link_id,audtype,audaction,audtext,auduser) values ('$COOKIE->{ACCT}',$FORM{id},'invoices','Delete','$Invoice_type $Invoice[6] deleted','$COOKIE->{USER}')");

#  4.  Update the additional fields of the invoice record 

	$Sts = $dbh->do("delete from invoices where id=$FORM{id} and acct_id='$COOKIE->{ACCT}'");

#  revert the next invoice no in companies

	$Sts = $dbh->do("update companies set comnextsi='$Invoice[6]' where reg_id=$Reg_id and id=$Com_id");

#  5.  Subtract from customer balance (if we have a cus id)

	if ($Invoice[1]) {
		$Sts = $dbh->do("update customers set cusbalance=cusbalance - $Tot where id=$Invoice[1] and acct_id='$COOKIE->{ACCT}'");
	}

#  6.  Subtract from the Debtors control (1100) and Sales Control (4000,4100,4200) coas

	$Sts = $dbh->do("update coas set coabalance=coabalance - $Tot where coanominalcode='1100' and acct_id='$COOKIE->{ACCT}'");
	$Sts = $dbh->do("update coas set coabalance=coabalance - $Invoice[3] where coanominalcode='$Invoice[2]' and acct_id='$COOKIE->{ACCT}'");
        $Sts = $dbh->do("delete from nominals where link_id=$FORM{id} and acct_id='$COOKIE->{ACCT}'");

#  7.  VAT

	unless ($COOKIE->{VAT} =~ /N/) {
		$Sts = $dbh->do("update coas set coabalance=coabalance - $Invoice[4] where coanominalcode='2100' and acct_id='$COOKIE->{ACCT}'");

#  Delete from VAT accruals and deduct from comvatcontrol

		$Sts = $dbh->do("delete from vataccruals where acct_id='$COOKIE->{ACCT}' and acrtxn_id=$FORM{id}");
	}

#  8.  Delete any entries in the items table

	$Sts = $dbh->do("delete from items where acct_id='$COOKIE->{ACCT}' and inv_id=$FORM{id}");

#  9.  Delete any images

	print<<EOD;
Content-Type: text/plain

OK
EOD

}
$Invoices->finish;
$dbh->disconnect;
exit;
