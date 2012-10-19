#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to cancel an existing, purchase invoice

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

use CGI;
use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");

$FORM{id} = $ENV{QUERY_STRING};

#  Check that the purchase invoice is not more than 1 day old

$Invoices = $dbh->prepare("select invtype,cus_id,invcoa,invtotal,invvat,invpaid,invstatuscode,invinvoiceno,to_days(invprintdate) - to_days(now()),invtotal+invvat-invpaid-invpaidvat from invoices where id=$FORM{id} and acct_id='$COOKIE->{ACCT}'");
$Invoices->execute;
@Invoice = $Invoices->fetchrow;

$Errs = "";

unless ($Invoices->rows > 0) { $Errs .= "<li>Invoice cannot be found</li>\n"; }
if ($Invoice[6] > 1 && $Invoice[8] > 0) { $Errs .= "<li>Only Purchase Invoices created today can be cancelled</li>\n"; }

if ($Errs) {
	print<<EOD;
Content-Type: text/plain

<ol>Invoice cannot be cancelled
$Errs
</ol>
EOD
}
else {
	($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});

#  Set the total invoice/credit note amount 

#  Remember that purchase invoice totals etc are all NEGATIVE!

	my $Tot = $Invoice[3] + $Invoice[4];
	my $Invoice_type = "Purchase Invoice";

#  2  write audit trail

	$Sts = $dbh->do("insert into audit_trails (acct_id,link_id,audtype,audaction,audtext,auduser) values ('$COOKIE->{ACCT}',$FORM{id},'invoices','Cancel','$Invoice_type $Invoice[7] cancelled','$COOKIE->{USER}')");

#  4.  Delete the invoice

        $Sts = $dbh->do("update invoices set invdesc=concat(invdesc,' - Cancelled'),invremarks=concat(invremarks,'<br/>Cancelled'),invstatus='Cancelled',invstatuscode='0',invstatusdate=now(),invtotal=0,invvat=0,invpaid=0,invpaidvat=0 where id=$FORM{id} and acct_id='$COOKIE->{ACCT}'");

#  If (and only if) the purchase invoice has a non-Draft status, update nominals and coas etc

	if ($Invoice[6] > 1) {
#  5.  Subtract from customer balance (if we have a cus id)

		if ($Invoice[1]) {
			$Sts = $dbh->do("update customers set cusbalance=cusbalance + $Tot where id=$Invoice[1] and acct_id='$COOKIE->{ACCT}'");
		}

#  6.  Subtract from the Creditors control (1100) and Expenses Control (4000,4100,4200) coas

		$Sts = $dbh->do("update coas set coabalance=coabalance + $Tot where coanominalcode='2000' and acct_id='$COOKIE->{ACCT}'");
	        $Sts = $dbh->do("insert into nominals (acct_id,link_id,nomtype,nomcode,nomamount,nomdate) values ('$COOKIE->{ACCT}',$FORM{id},'S','2000','$Tot',now())");

		$Sts = $dbh->do("update coas set coabalance=coabalance + $Invoice[3] where coanominalcode='$Invoice[2]' and acct_id='$COOKIE->{ACCT}'");
	        $Sts = $dbh->do("insert into nominals (acct_id,link_id,nomtype,nomcode,nomamount,nomdate) values ('$COOKIE->{ACCT}',$FORM{id},'S','$Invoice[2]','$Invoice[3]',now())");

#  7.  VAT

		unless ($COOKIE->{VAT} =~ /N/) {
			$Sts = $dbh->do("update coas set coabalance=coabalance + $Invoice[4] where coanominalcode='1400' and acct_id='$COOKIE->{ACCT}'");
	        	$Sts = $dbh->do("insert into nominals (acct_id,link_id,nomtype,nomcode,nomamount,nomdate) values ('$COOKIE->{ACCT}',$FORM{id},'S','1400','$Invoice[4]',now())");

#  Delete from VAT accruals and deduct from comvatcontrol

			$Sts = $dbh->do("delete from vataccruals where acct_id='$COOKIE->{ACCT}' and acrtxn_id=$FORM{id}");
		}
	}

	print<<EOD;
Content-Type: text/html
Status: 302
Location: /cgi-bin/fpa/list_purchases.pl

EOD

}
$Invoices->finish;
$dbh->disconnect;
exit;
