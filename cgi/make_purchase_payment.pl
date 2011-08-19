#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to make payment for an invoice (or receive a refund)

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

while (($Key,$Value) = each %FORM) {

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

unless ($FORM{txnamount} =~ /^\-?\d+\.?\d?\d?$/) { $Errs .= "<li>$FORM{txnamount} - You must enter the amount being paid</li>\n"; }

#open(FILE,">>/tmp/fpa1.txt");
#while (($Key,$Value) = each %FORM) {
#	print FILE  "$Key = $Value\n";
#}
#close(FILE);

if ($Errs) {
	print<<EOD;
Content-Type: text/plain

Errors!

$Errs
EOD
}
else {

#  Before we do anything else, set the invcoa depending on whether invcusregion = UK/EU/NEU.

        $FORM{invcusregion} = $FORM{invcusregion} || 'UK';

#  Get the customer name

	$Customers = $dbh->prepare("select cusname from customers where acct_id='$COOKIE->{ACCT}' and id=$FORM{cus_id}");
	$Customers->execute;
	($FORM{invcusname}) = $Customers->fetchrow;
        $FORM{invcusname} =~ s/\'/\\\'/g;
	$Customers->finish;

	require "/usr/local/httpd/cgi-bin/fpa/process_purchase.ph";
	$FORM{invtype} = "P";
	&money_out();
	&pay_invoice();
	print<<EOD;
Content-Type: text/plain

OK-Payment processed
EOD
}
$dbh->disconnect;
exit;
