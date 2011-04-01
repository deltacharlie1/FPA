#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to process a generalised Money In / Money Out transaction

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
# exit;

#  Do some basic validation

$Errs = "";

warn "invtype = $FORM{invtype}\n";

if ($FORM{invtype} =~ /I/i) {
	unless ($FORM{invcusname}) { $Errs .= "<li>You must enter the Customer's name</li>\n"; }
}
 elsif ($FORM{invtype} =~ /P/) {
	unless ($FORM{invcusname}) { $Errs .= "<li>You must enter the Supplier's name</li>\n"; }
}
unless ($FORM{txnamount} =~ /^-?\d+\.?\d?\d?$/) { $Errs .= "<li>$FORM{txnamount} - You must enter the amount being paid</li>\n"; }

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
		&save_invoice();		#  create a dummy invoice
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

		&save_invoice();
		unless ($Expense_type =~ /E/i) {	#  ie if not expenses
			&money_out();
			&pay_invoice();
		}
		print<<EOD;
Content-Type: text/plain

OK-$FORM{id}-list_customer_purchases.pl?$FORM{cus_id}
EOD
	}
}
$dbh->disconnect;
exit;
