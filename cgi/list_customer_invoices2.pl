#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to update customer details

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

use CGI;
use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");

$Data = new CGI;
%FORM = $Data->Vars;

$Upds = "";

while (( $Key,$Value) = each %FORM) {

#  Remove any bad characters

	$Value =~ tr/\\//d;
	$Value =~ s/\'/\\\'/g;
        $FORM{$Key} = $Value;

}

#  Do some basic validation

$Errs = "";

unless ($FORM{cusname}) { $Errs .= "<li>No Company Name</li>\n"; }
unless ($FORM{id} > 0) { $Errs .= "<li>There is no Customer Identifier - cannot update</li>\n"; }

if ($Errs) {
	print<<EOD;
Content-Type: text/plain

Errors!

$Errs
EOD
}
else {
#	if ($FORM{ignore_action} =~ /Delete/i) {	#  Delete
#		$Sts = $dbh->do("delete from customers where acct_id='$COOKIE->{ACCT}' and id=$FORM{id}");
#	}

	if ($FORM{id} > 0) {	#  An Update

		$Sts = $dbh->do("update customers set cusname='$FORM{cusname}',cusaddress='$FORM{cusaddress}',cuspostcode='$FORM{cuspostcode}',cusregion='$FORM{cusregion}',custel='$FORM{custel}',cuscontact='$FORM{cuscontact}',cusemail='$FORM{cusemail}',custerms='$FORM{custerms}',cusdefpo='$FORM{cusdefpo}',cusbank='$FORM{cusbank}',cussortcode='$FORM{cussortcode}',cusacctno='$FORM{cusacctno}',cusbalance='$FORM{cusbalance}',cuslimit='$FORM{cuslimit}',cussales='$FORM{cussales}',cussupplier='$FORM{cussupplier}',cusremarks='$FORM{cusremarks}' where acct_id='$COOKIE->{ACCT}' and id=$FORM{id}");
		$Href = "list_customer_invoices.pl?$FORM{id}";
	}
	
	print<<EOD;
Content-Type: text/plain\n\n

OK-$Href-

EOD
}
$dbh->disconnect;
exit;
