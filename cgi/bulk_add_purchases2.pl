#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  Save new purchases for a bookkeeper's client

#  Column order is:-

#  0 - Nominal Acct
#  1 - Customer
#  2 - Cus ID
#  3 - Cus Cis (Y/N)
#  4 - Description
#  5 - Net Amount (VAT registered only)
#  6 - VAT Amount (VAT Registered only)
#  7 - Total
#  8 - Invoice Date
#  9 - Payment Method
#  10 - Category
#  11 - Reference
#  12 - Paid in Full flag (Y/ )
# 13 - Vat Rate

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

use CGI;
use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");

require "/usr/local/httpd/cgi-bin/fpa/process_purchase.ph";

$Curdate = `date +%m-%Y`;
chomp($Curdate);

$Data = new CGI;
%FORM = $Data->Vars;

while (( $Key,$Value) = each %FORM) {

#  Remove any bad characters

	$Value =~ s/\%2b/\+/ig;
	$Value =~ tr/\\//d;
	$Value =~ s/\'/\\\'/g;
        $DATA{$Key} = $Value;
}

($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});

$DATA{data} =~ s/<(?!\/).+?>//g;
$DATA{data} =~ s/<\/tr>/\n/ig;
$DATA{data} =~ s/<\/td>/\t/ig;

@Invoices = split(/\n/,$DATA{data});
foreach $Invoice (@Invoices) {
	@bCell = split(/\t/,$Invoice);
	if ($bCell[1]) {
		$bCell[5] = $bCell[5] || $bCell[7];     #  Make sure that invtotal has got something in it
		$FORM{id} = "";
		$FORM{invitems} = "";
		$FORM{invtype} = "P";
		$FORM{invcoa} = $bCell[0];
		$FORM{invcusname} = $bCell[1];
		$FORM{cus_id} = $bCell[2];
		$FORM{invdesc} = $bCell[4];
		$FORM{invtotal} = sprintf('%1.2f',$bCell[5]);
		$FORM{invvat} = sprintf('%1.2f',$bCell[6]);
		$FORM{txnamount} = sprintf('%1.2f',$bCell[7]);
		$FORM{invprintdate} = $bCell[8] || $Curdate;
		$FORM{txnmethod} = $bCell[9];
		$FORM{item_cat} = $bCell[10];
		$FORM{invcusref} = $bCell[11];
		$FORM{vatrate} = $bCell[13];;

		&save_invoice('final');

                if ($bCell[12] =~ /Y/i) {         #  Paid in Full?
                        &money_out();
                        &pay_invoice();
                }
	}
}
$dbh->disconnect;
print<<EOD;
Content-Type: text/plain
Status: 301
Location: /cgi-bin/fpa/list_purchases.pl

EOD
exit;
