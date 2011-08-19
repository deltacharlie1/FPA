#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to receive payment for an invoice (or make a refund for a credit note)

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

use CGI;
use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");
unless ($COOKIE->{NO_ADS}) {
	require "/usr/local/git/fpa/cgi/display_adverts.ph";
	&display_adverts();
}


$Multi = "";		#  Used to detmine which page we return to

$Data = new CGI;
%FORM = $Data->Vars;

# print "Content-Type: text/plain\n\n";

while (( $Key,$Value) = each %FORM) {

#  Remove any bad characters

	$Value =~ tr/\\//d;
	$Value =~ s/\'/\\\'/g;
	$FORM{$Key} = $Value;

# print "$Key = $Value<br/>\n";

#  See if we have checkboxes (ie multi receipts)

	if ($Key =~ /^i\d+$/) {
		$Multi = "1";
		$Key =~ s/^i//;
		$Invoice_ids .= $Key.",";
	}

# print "$Key = $Value\n";
}
# exit;

#  Do some basic validation

$Errs = "";

unless ($FORM{txnamount} =~ /^\d+\.?\d?\d?$/) { $Errs .= "<li>You must enter the amount being paid</li>\n"; }

if ($Errs) {
	print<<EOD;
Content-Type: text/plain

You have the following error(s):-<ol>$Errs</ol>Please correct them and re-submit
EOD
}
else {

	require "/usr/local/httpd/cgi-bin/fpa/process_invoice.ph";
	$FORM{invtype} = "S";
	&money_in();
	@Inv_id = split(/\,/,$Invoice_ids);

	foreach $i (@Inv_id) {
		$FORM{id} = $i;
		$FORM{txnamount} = sprintf("%1.2f",$FORM{txnamount});
		last if ($FORM{txnamount} <= 0);
		&pay_invoice();
	}

	print<<EOD;
Content-Type: text/plain

OK-list_customer_invoices.pl?$FORM{cus_id}-

EOD
}
$dbh->disconnect;
exit;
