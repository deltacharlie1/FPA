#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to refund the outstanding amount of an invoice

#  1 - The invoice in question is converted to fully paid
#  2 - A credit note for the balance is raised

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
%FORM2 = $Data->Vars;

# print "Content-Type: text/plain\n\n";

while (($Key,$Value) = each %FORM2) {

#  Remove any prefixed differentiator from input field names

	$Key =~ s/^._//;

#  Remove any bad characters

	$Value =~ tr/\\//d;
	$Value =~ s/\'/\\\'/g;
	$FORM{$Key} = $Value;

# print "$Key = $Value<br/>\n";

# print "$Key = $Value\n";
}
# exit;

#  Do some basic validation

# $FORM{id} = $FORM{i_id};

$Errs = "";

#  Get the outstanding balance of the invoice

$Invoices = $dbh->prepare("select id,invinvoiceno,invtotal+invvat-invpaid-invpaidvat as owed,invtotal-invpaid as netowed,invvat-invpaidvat as vatowed,invcusregion,invcusname from invoices where acct_id='$COOKIE->{ACCT}' and id=$FORM{id}");
$Invoices->execute;
$Invoice = $Invoices->fetchrow_hashref;
$Invoices->finish;

unless ($Invoice->{owed} == $FORM{txnamount}) { $Errs .= "At $FORM{txnamount}, amount to be refunded does not equal outstanding balance of $Invoice->{owed}"; }

if ($Errs) {
	print<<EOD;
Content-Type: text/plain

Errors!

$Errs
EOD
}
else {

#  Before we do anything else, set the invcoa depending on whether invcusregion = UK/EU/NEU.

        $FORM{invcusregion} = $Invoice->{invcusregion} || 'UK';

        if ($FORM{invcusregion} =~ /UK/i) {
                $FORM{invcoa} = "4000";
        }
        elsif ($FORM{invcusregion} =~ /NEU/i) {
                $FORM{invcoa} = "4200";
        }
        else {
                $FORM{invcoa} = "4100";
        }

	$Original_invoice_id = $FORM{id};

#  add an invtxn record

	$Sts = $dbh->do("insert into inv_txns (acct_id,inv_id,itinvoiceno,itnet,itvat,itdate,itmethod) values ('$COOKIE->{ACCT}',$FORM{id},'$Invoice->{invinvoiceno}','$Invoice->{netowed}','$Invoice->{vatowed}',str_to_date('$FORM{invprintdate}','%d-%b-%y'),'refund')");

#  The customer's balance is reduced by the Credit Note processing

	require "/usr/local/httpd/cgi-bin/fpa/process_invoice.ph";
	$FORM{invtype} = "C";
	$FORM{invcusname} = $Invoice->{invcusname};
	$FORM{id} = "";
	$FORM{invtotal} = $Invoice->{netowed};
	$FORM{invvat} = $Invoice->{vatowed};
	$FORM{invremarks} = "Refund in respect of Invoice $Invoice->{invinvoiceno}";

	&save_invoice();

#  Update the original invoice to fully paid

	$Sts = $dbh->do("update invoices set invpaid=invtotal,invvat=invpaidvat,invstatus='Paid',invstatuscode='2',invpaiddate=str_to_date('$FORM{invprintdate}','%d-%b-%y'),invremarks=concat(invremarks,'<br/><br/>&pound;$Invoice->{owed} refunded via Credit Note $FORM{invinvoiceno}') where acct_id='$COOKIE->{ACCT}' and id=$Invoice->{id}");

#  move the Credit Note to a fully paid status

	$Sts = $dbh->do("update invoices set invstatus='Paid',invstatuscode='2',invpaiddate=str_to_date('$FORM{invprintdate}','%d-%b-%y'),invpaid=invtotal,invpaidvat=invvat where acct_id='$COOKIE->{ACCT}' and id=$FORM{id}");

#  Add an audit trail entry

	$Sts = $dbh->do("insert into audit_trails (acct_id,link_id,audtype,audaction,audtext,auduser) values ('$COOKIE->{ACCT}',$Invoice->{id},'update_invoice.pl','refund','Invoice $Invoice->{invinvoiceno} refunded &pound;$Invoice->{owed} via Credit Note $FORM{invinvoiceno}','$COOKIE->{USER}')");

	print<<EOD;
Content-Type: text/plain

Refund processed.

Credit Note $FORM{invinvoiceno} raised.
EOD
}
$dbh->disconnect;
exit;
