#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to cancel an existing, unpaid Purchase Invoice.  If it is paid up then the payment must first be cancelled (if it can)

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

use CGI;
use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");

$Data = new CGI;
%FORM = $Data->Vars;
while (( $Key,$Value) = each %FORM) {

#  Remove any bad characters

        $Value =~ s/\%2b/\+/ig;
        $Value =~ tr/\\//d;
        $Value =~ s/\'/\\\'/g;
        $FORM{$Key} = $Value;
}

#  Check that nothing has yet been paid (if it has then the user will have to raise a separate credit note)

$Invoices = $dbh->prepare("select invtype,cus_id,invcoa,invtotal,invvat,invpaid,invstatuscode,invinvoiceno from invoices where id=$FORM{id} and acct_id='$COOKIE->{ACCT}'");
$Invoices->execute;
@Invoice = $Invoices->fetchrow;

$Errs = "";

unless ($Invoices->rows > 0) { $Errs .= "<li>Purchase Invoice cannot be found</li>\n"; }
if ($Invoice[5] != 0) { $Errs .= "<li>Purchase Invoice is at least Part Paid, please raise a balancing Credit Note</li>\n"; }
if ($Invoice[6] < 1) { $Errs .= "<li>Purchase Invoice has already been voided</li>\n"; }

if ($Errs) {
	print<<EOD;
Content-Type: text/plain

<ol>Invoice cannot be voided
$Errs
</ol>
EOD
}
else {
	($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});

#  Set the total invoice/credit note amount 
#  Remember that purchase invoice amouunts start off as negative!!

	my $Tot = $Invoice[3] + $Invoice[4];
	my $Invoice_type = "Purchase Invoice";
	if ($Invtype =~ /R/i) {		#  Refund, so reverse amounts
		$Invoice[3] = 0 - $Invoice[3];
		$Invoice[4] = 0 - $Invoice[4];
		$Tot = 0 - $Tot;
		$Invoice_type = "Refund";
	}

#  2  write audit trail

	$Sts = $dbh->do("insert into audit_trails (acct_id,link_id,audtype,audaction,audtext,auduser) values ('$COOKIE->{ACCT}',$FORM{id},'invoices','Cancel','$Invoice_type $Invoice[7] voided - $FORM{cancelmsg}','$COOKIE->{USER}')");

#  4.  Update the additional fields of the invoice record 

	$Sts = $dbh->do("update invoices set invremarks=concat(invremarks,'<br/>$FORM{cancelmsg}'),invstatus='Voided',invstatuscode='0',invstatusdate=now(),invtotal=0,invvat=0 where id=$FORM{id} and acct_id='$COOKIE->{ACCT}'");

#  Update nominals, coas etc only if status is not Draft

	if ($Invoice[6] > 1) {

#  5.  Add to customer balance (if we have a cus id)

		if ($Invoice[1]) {
			$Sts = $dbh->do("update customers set cusbalance=cusbalance + $Tot where id=$Invoice[1] and acct_id='$COOKIE->{ACCT}'");
		}

#  6.  Reverse coa entries from nominal leder

		$Noms = $dbh->prepare("select * from nominals where acct_id='$COOKIE->{ACCT}' and nomtype='S' and link_id=$FORM{id}");
		$Noms->execute;
		while ($Nom = $Noms->fetchrow_hashref) {

			$Sts = $dbh->do("update coas set coabalance=coabalance - '$Nom->{nomamount}' where coanominalcode='$Nom->{nomcode}' and acct_id='$COOKIE->{ACCT}'");
		}

#  Now delete those ledger entries

		$Sts = $dbh->do("delete from nominals where acct_id='$COOKIE->{ACCT}' and nomtype='S' and link_id=$FORM{id}");


#  7.  VAT

		if ($COOKIE->{VAT} =~ /S/) {  #  In this case link_id = inv id

#  Delete from VAT accruals and deduct from comvatcontrol

			$Sts = $dbh->do("delete from vataccruals where acct_id='$COOKIE->{ACCT}' and acrtxn_id=$FORM{id}");
		}
#  Delete entries from the nominal ledger

		$Sts = $dbh->do("delete from nominals where acct_id='$COOKIE->{ACCT}' and nomtype='S' and link_id=$FORM{id}");

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
