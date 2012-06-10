#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to add/update customer details

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

$Flds = "";
$Data = "";
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

#  Change paymethod to 1200 if Cheque and Supplier

	if ($FORM{cusdefpaymethod} =~ /1310/ && $FORM{custype} =~ /S/i) {
		$FORM{cusdefpaymethod} = "1200";
	}

#  Change default expenses category (defcoa) if supplier

	if ($FORM{cusdefcoa} =~ /4000/ && $FORM{custype} =~ /S/i) {
		$FORM{cusdefcoa} = "5000";
	}

	if ($FORM{id} > 0) {	#  An Update

		$Sts = $dbh->do("update customers set cusdeliveryaddr='$FORM{cusdeliveryaddr}',cusname='$FORM{cusname}',cusaddress='$FORM{cusaddress}',cuspostcode='$FORM{cuspostcode}',cusregion='$FORM{cusregion}',custel='$FORM{custel}',cuscontact='$FORM{cuscontact}',cusemail='$FORM{cusemail}',custerms='$FORM{custerms}',cusdefpo='$FORM{cusdefpo}',cusbank='$FORM{cusbank}',cussortcode='$FORM{cussortcode}',cusacctno='$FORM{cusacctno}',cuslimit='$FORM{cuslimit}',cussales='$FORM{cussales}',cussupplier='$FORM{cussupplier}',cusremarks='$FORM{cusremarks}',cusdefpaymethod='$FORM{cusdefpaymethod}',cusdefcoa='$FORM{cusdefcoa}',cusdefvatrate='$FORM{cusdefvatrate}',cusemailmsg='$FORM{cusemailmsg}',cusstmtmsg='$FORM{cusstmtmsg}',cusautostmts='$FORM{cusautostmts}',cuscis='$FORM{cuscis}',cuslayout='$FORM{cuslayout}',cussuppress='$FORM{cussuppress}' where acct_id='$COOKIE->{ACCT}' and id=$FORM{id}");

	}
	else {				#  A new record (in theory!)
		$Sts = $dbh->do("insert into customers (acct_id,cusname,cusaddress,cuspostcode,cusregion,custel,cuscontact,cusemail,custerms,cusdefpo,cusbank,cussortcode,cusacctno,cusbalance,cuslimit,cussales,cussupplier,cusremarks,cusdefpaymethod,cusdefvatrate,cusemailmsg,cusstmtmsg,cusautostmts,cuscis,cuslayout,cusdeliveryaddr,cussuppress,cusdefcoa) values ('$COOKIE->{ACCT}','$FORM{cusname}','$FORM{cusaddress}','$FORM{cuspostcode}','$FORM{cusregion}','$FORM{custel}','$FORM{cuscontact}','$FORM{cusemail}','$FORM{custerms}','$FORM{cusdefpo}','$FORM{cusbank}','$FORM{cussortcode}','$FORM{cusacctno}','0','$FORM{cuslimit}','$FORM{cussales}','$FORM{cussupplier}','$FORM{cusremarks}','$FORM{cusdefpaymethod}','$FORM{cusdefvatrate}','$FORM{cusemailmsg}','$FORM{cusstmtmsg}','$FORM{cusautostmts}','$FORM{cuscis}','$FORM{cuslayout}','$FORM{cusdeliveryaddr}','$FORM{cussuppress}','$FORM{cusdefcoa}')");
		$Href = "add_address.pl?$FORM{custype}";
	}

	if ($FORM{custype} =~ /S/i) {
		$Href = "list_suppliers.pl";
	}
	else {
		$Href = "list_customers.pl";
	}
	
	print<<EOD;
Content-Type: text/plain

OK-$Href-

EOD
}
$dbh->disconnect;
exit;
