#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to make a payment for an invoice

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

use CGI;
use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");

$Data = new CGI;
%FORM = $Data->Vars;

# print "Content-Type: text/plain\n\n";

while (($Key,$Value) = each %FORM) {

#  Remove any prefixed differentiator from input field names

#	$Key =~ s/^._//;

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

unless ($FORM{txnamount} =~ /^\d+\.?\d?\d?$/) { $Errs .= "<li>$FORM{txnamount} - You must enter the amount being paid</li>\n"; }

#while (($Key,$Value) = each %FORM) {
#	$Errs .= "$Key = $Value\n";
#}

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
#	$FORM{txnamount} = 0 - $FORM{txnamount};

	&money_out();
	&pay_purchase();
	print<<EOD;
Content-Type: text/plain

OK-Payment processed
EOD
}
$dbh->disconnect;
exit;
