#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to cancel an existing, Final, invoice

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

unless ($Invoices->rows > 0) { $Errs .= "<li>Invoice cannot be found</li>\n"; }
if ($Invoice[5] > 0) { $Errs .= "<li>Invoice is at least Part Paid, please raise a balancing Credit Note</li>\n"; }
if ($Invoice[6] < 1) { $Errs .= "<li>Invoice has already been voided</li>\n"; }

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

	my $Tot = $Invoice[3] + $Invoice[4];
	my $Invoice_type = "Invoice";
	if ($Invtype =~ /C/i) {		#  Credit Note, so reverse amounts
		$Invoice[3] = 0 - $Invoice[3];
		$Invoice[4] = 0 - $Invoice[4];
		$Tot = 0 - $Tot;
		$Invoice_type = "Credit Note";
	}

#  2  write audit trail

	$Sts = $dbh->do("insert into audit_trails (acct_id,link_id,audtype,audaction,audtext,auduser) values ('$COOKIE->{ACCT}',$FORM{id},'invoices','Cancel','$Invoice_type $Invoice[7] voided - $FORM{cancelmsg}','$COOKIE->{USER}')");

#  4.  Update the additional fields of the invoice record 

	$Sts = $dbh->do("update invoices set invremarks=concat(invremarks,'<br/>$FORM{cancelmsg}'),invstatus='Voided',invstatuscode='0',invstatusdate=now(),invtotal=0,invvat=0 where id=$FORM{id} and acct_id='$COOKIE->{ACCT}'");

#  Update nominals, coas etc only if status is not Draft

	if ($Invoice[6] > 1) {
#  5.  Subtract from customer balance (if we have a cus id)

		if ($Invoice[1]) {
			$Sts = $dbh->do("update customers set cusbalance=cusbalance - $Tot where id=$Invoice[1] and acct_id='$COOKIE->{ACCT}'");
		}

#  6.  Subtract from the Debtors control (1100) and Sales Control (4000,4100,4200) coas

		$Sts = $dbh->do("update coas set coabalance=coabalance - $Tot where coanominalcode='1100' and acct_id='$COOKIE->{ACCT}'");
	        $Sts = $dbh->do("insert into nominals (acct_id,link_id,nomtype,nomcode,nomamount,nomdate) values ('$COOKIE->{ACCT}',$FORM{id},'S','1100','-$Tot',now())");


		$Sts = $dbh->do("update coas set coabalance=coabalance - $Invoice[3] where coanominalcode='$Invoice[2]' and acct_id='$COOKIE->{ACCT}'");
	        $Sts = $dbh->do("insert into nominals (acct_id,link_id,nomtype,nomcode,nomamount,nomdate) values ('$COOKIE->{ACCT}',$FORM{id},'S','$Invoice[2]','-$Invoice[3]',now())");

#  7.  VAT

		unless ($COOKIE->{VAT} =~ /N/) {
			$Sts = $dbh->do("update coas set coabalance=coabalance - $Invoice[4] where coanominalcode='2100' and acct_id='$COOKIE->{ACCT}'");
	        	$Sts = $dbh->do("insert into nominals (acct_id,link_id,nomtype,nomcode,nomamount,nomdate) values ('$COOKIE->{ACCT}',$FORM{id},'S','2100','-$Invoice[4]',now())");
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
