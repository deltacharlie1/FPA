#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to pay an invoice

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

unless ($FORM{txnamount} =~ /^\d+\.?\d?\d?$/) { $Errs .= "<li>$FORM{txnamount} - You must enter the amount being paid</li>\n"; }

if ($Errs) {
	print<<EOD;
Content-Type: text/plain

Errors!

$Errs
EOD
}
else {

	require "/usr/local/httpd/cgi-bin/fpa/process_purchase.ph";
	$FORM{invtype} = "P";
	&money_out();
	@Inv_id = split(/\,/,$Invoice_ids);

	foreach $i (@Inv_id) {
		$FORM{id} = $i;
#		last if ($FORM{txnamount} >= 0);
		&pay_invoice();
	}

	print<<EOD;
Content-Type: text/plain

OK-list_supplier_purchases.pl?$FORM{cus_id}-

EOD
}
$dbh->disconnect;
exit;
