#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to add a new invoice 

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

# print "$Key = $Value\n";
}
# exit;

#  Do some basic validation

$Errs = "";

unless ($FORM{invcusname}) { $Errs .= "<li>You must enter a Customer Name</li>\n"; }
unless ($FORM{invitemcount} > 0) { $Errs .= "<li>You have not entered any line items, empty invoice!</li>\n"; }

if ($Errs) {
	print<<EOD;
Content-Type: text/plain

Errors!

$Errs
EOD
}
else {

#  Is this a new Draft Invoice (or credit note?)

	require "/usr/local/httpd/cgi-bin/fpa/process_purchase.ph";

	$FORM{txnamount} = $FORM{invtotal} + $FORM{invvat};
	&save_purchase('final');

	if ($FORM{invfpflag} =~ /Y/i) {		#  Paid in full?
		&money_out();
		&pay_purchase();
	}

        if ($FORM{submit} =~ /Print/i) {

                print<<EOD;
Content-Type: text/plain

OK-preview_purchase.pl?$FORM{id}

EOD
        }
        else {
	        print<<EOD;
Content-Type: text/plain

OK-update_purchase.pl?$FORM{id}

EOD
        }


}
$dbh->disconnect;
exit;
