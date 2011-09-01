#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to write-off an existing, Final, invoice

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

use CGI;
use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");
unless ($COOKIE->{NO_ADS}) {
	require "/usr/local/git/fpa/cgi/display_adverts.ph";
	&display_adverts();
}


$Data = new CGI;
%FORM = $Data->Vars;

$Invoices = $dbh->prepare("select invtype,cus_id,invcoa,invtotal-invpaid,invvat-invpaidvat,invpaid,invstatuscode,invinvoiceno from invoices where id=$FORM{id} and acct_id='$COOKIE->{ACCT}'");
$Invoices->execute;
@Invoice = $Invoices->fetchrow;

$Errs = "";

unless ($Invoices->rows > 0) { $Errs .= "<li>Invoice cannot be found</li>\n"; }
if ($Invoice[6] < 1) { $Errs .= "<li>Invoice has already been Written-off</li>\n"; }

if ($Errs) {
	print<<EOD;
Content-Type: text/plain

<ol>Invoice cannot be written-off 
$Errs
</ol>
EOD
}
else {
	($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});

#  Set the total invoice/credit note amount 

	my $Tot = $Invoice[3] + $Invoice[4];
	my $Invoice_type = "Invoice";
	my $Invtype = "S";
	if ($Invtype =~ /C/i) {		#  Credit Note, so reverse amounts
		$Invoice[3] = 0 - $Invoice[3];
		$Invoice[4] = 0 - $Invoice[4];
		$Tot = 0 - $Tot;
		$Invoice_type = "Credit Note";
		$Invtype = "C";
	}

#  2  write audit trail

	$Sts = $dbh->do("insert into audit_trails (acct_id,link_id,audtype,audaction,audtext,auduser) values ('$COOKIE->{ACCT}',$FORM{id},'invoices','Write-off','$Invoice_type $Invoice[7] written off - $FORM{writeoffmsg}','$COOKIE->{USER}')");

#  4.  Update the additional fields of the invoice record 

	$Sts = $dbh->do("update invoices set invremarks=concat(invremarks,'<br/>$FORM{writeoffmsg}'),invstatus='Written off',invstatuscode='0',invstatusdate=now(),invtotal=0,invvat=0 where id=$FORM{id} and acct_id='$COOKIE->{ACCT}'");

#  Only update nominals, coas etc if status not Draft

	if ($Invoice[6] > 1) {

#  5.  Subtract from customer balance (if we have a cus id)

		if ($Invoice[1]) {
			$Sts = $dbh->do("update customers set cusbalance=cusbalance - $Tot where id=$Invoice[1] and acct_id='$COOKIE->{ACCT}'");
		}

#  6.  Subtract from the Debtors control (1100) and add to Bad Debts (8000)

		$Sts = $dbh->do("update coas set coabalance=coabalance - $Tot where coanominalcode='1100' and acct_id='$COOKIE->{ACCT}'");
	        $Sts = $dbh->do("insert into nominals (acct_id,link_id,nomtype,nomcode,nomamount,nomdate) values ('$COOKIE->{ACCT}',$FORM{id},'$Invtype','1100','-$Tot',now())");


		$Sts = $dbh->do("update coas set coabalance=coabalance + $Invoice[3] where coanominalcode='8000' and acct_id='$COOKIE->{ACCT}'");
        $Sts = $dbh->do("insert into nominals (acct_id,link_id,nomtype,nomcode,nomamount,nomdate) values ('$COOKIE->{ACCT}',$FORM{id},'$Invtype','$Invoice[2]','-$Invoice[3]',now())");

#  7.  VAT

		unless ($COOKIE->{VAT} =~ /N/) {
			$Sts = $dbh->do("update coas set coabalance=coabalance - $Invoice[4] where coanominalcode='2100' and acct_id='$COOKIE->{ACCT}'");
        		$Sts = $dbh->do("insert into nominals (acct_id,link_id,nomtype,nomcode,nomamount,nomdate) values ('$COOKIE->{ACCT}',$FORM{id},'$Invtype','2100','-$Invoice[4]',now())");
			if ($COOKIE->{VAT} =~ /S/) {

#  Delete from VAT accruals and deduct from comvatcontrol

				$Sts = $dbh->do("delete from vataccruals where acct_id='$COOKIE->{ACCT}' and acrtxn_id=$FORM{id}");
			}
		}

#  8.  Delete any entries in the items table

		$Sts = $dbh->do("delete from items where acct_id='$COOKIE->{ACCT}' and inv_id=$FORM{id}");
	}

	print<<EOD;
Content-Type: text/plain

OK
EOD

}
$Invoices->finish;
$dbh->disconnect;
exit;
