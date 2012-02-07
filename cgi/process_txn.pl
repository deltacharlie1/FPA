#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to process a generalised Money In / Money Out transaction

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

# print "Content-Type: text/plain\n\n";

while (( $Key,$Value) = each %FORM) {

#  Remove any bad characters

	$Value =~ tr/\\//d;
	$Value =~ s/\'/\\\'/g;
	$FORM{$Key} = $Value;
}
# exit;

#  Do some basic validation

$Errs = "";

#if ($FORM{cuscis} =~ /Y/i) {
#	$Errs .= "You cannot use this option to record CIS Contractor payments\n";
#}
if ($FORM{invtype} =~ /I/i) {
	unless ($FORM{invcusname}) { $Errs .= "You must enter the Customer's name\n"; }
}
 elsif ($FORM{invtype} =~ /P/) {
	unless ($FORM{invcusname}) { $Errs .= "You must enter the Supplier's name\n"; }
}
unless ($FORM{txnamount} =~ /^-?\d+\.?\d?\d?$/) { $Errs .= "$FORM{txnamount} - You must enter the amount being paid\n"; }

if ($Errs) {
	print<<EOD;
Content-Type: text/plain

Errors!

$Errs
EOD
}
else {
	$FORM{cus_id} = $FORM{amtcusid};
	$FORM{invtotal} = $FORM{txnamount} - $FORM{invvat};
	$FORM{invcusregion} = $FORM{invcusregion} || 'UK';

	if ($FORM{invtype} =~ /I/i) {

#  Money In transaction

		$FORM{invtype} = "S";

		require "/usr/local/httpd/cgi-bin/fpa/process_invoice.ph";

#  Check to see if we have an invoice number (and only an invoice number) in rec_invdesc (remarks)

		if ($FORM{invdesc} =~ /^Invoice\s\d+$/i) {

#  We do so see if we can find that invoice

			$Inv_no = $FORM{invdesc};
			$Inv_no =~ s/.*\s(\d+)$/$1/;
			$Invoices = $dbh->prepare("select id from invoices where invinvoiceno='$Inv_no' and acct_id='$COOKIE->{ACCT}'");
			$Invoices->execute;
			if ($Invoices->rows > 0) {
				($FORM{id}) = $Invoices->fetchrow;
			}
			else {
				&save_invoice();
			}
			$Invoices->finish;
		}
		else {
			&save_invoice();		#  create a dummy invoice
		}
		if ($FORM{cuscis} =~ /Y/i) {
			$FORM{txnamount} = $FORM{txnpaid} || $FORM{txnamount};
		}
		&money_in();
		&pay_invoice();

		print<<EOD;
Content-Type: text/plain

OK-list_customer_invoices.pl?$FORM{cus_id}
EOD
	}
	else {

#  Money out (purchase) transaction

		$Expense_type = $FORM{invtype};

		$FORM{invtype} = "P";

		require "/usr/local/httpd/cgi-bin/fpa/process_purchase.ph";

		&save_purchase();
		unless ($Expense_type =~ /E/i) {	#  ie if not expenses
			&money_out();
			&pay_purchase();
		}
		print<<EOD;
Content-Type: text/plain

OK-$FORM{id}-list_customer_purchases.pl?$FORM{cus_id}
EOD
	}
}
$dbh->disconnect;
exit;
