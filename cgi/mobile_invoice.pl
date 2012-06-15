#!/usr/bin/perl

#  script to display the main cover sheet updating screen

#  Processing:-
#  1.  Check user is setup to receive mobile invoices
#  2.  Get reg_id,id,vatscheme
#  3.  Get input invoice details
#  4.  See if customer exists and, if so, get id
#  5.  Call process_invoice.ph


#read(STDIN, $Buffer, $ENV{'CONTENT_LENGTH'});

#@pairs = split(/&/,$Buffer);

#foreach $pair (@pairs) {

#	($Name, $Value) = split(/=/, $pair);

#	$Value =~ tr/+/ /;
#	$Value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C",hex($1))/eg;
#	$FORM{$Name} = $Value;
#}

#open(EMAIL,"| /usr/sbin/sendmail -t");
#print EMAIL <<EOD;
#From: Registrations <fparegistrations\@corunna.com>
#To: doug.conran\@corunna.com
#Subject: Mobile Invoice

#QUERY_STRING = $ENV{QUERY_STRING}

#-------

#Buffer (Post data) = $Buffer

#-------

#EOD

$Buffer = <<EOD;
<?xml version='1.0' encoding='UTF-8' standalone='yes' ?><freeplusinvoice><header><phone_number>07899988701</phone_number><user>DC</user><invoice_count>1</invoice_count></header><invoice><invoice_number>M00007</invoice_number><invoice_date>14-6-2012</invoice_date><customer_name>Doug Conran</customer_name><customer_address>8 Tupman Walk
Bury St Edmunds
Suffolk
</customer_address><customer_postcode>IP33 1AJ</customer_postcode><customer_email>doug.conran\@corunna.com</customer_email><customer_telephone></customer_telephone><customer_contact></customer_contact><customer_ref></customer_ref><customer_terms>Paid</customer_terms><amount_paid>720.00</amount_paid><payment_remarks></payment_remarks><payment_method>Trans</payment_method><payment_action>Paid</payment_action><payment_currency>£</payment_currency><payment_currency1>£</payment_currency1><invoice_net>600.00</invoice_net><invoice_vat>120.00</invoice_vat><><line_items><item><title>Consultancy</title><description>Consultancy @ £60 per hour</description><price>60.00</price><qty>3</qty><net>180.00</net><vat_percent>20.00</vat_percent><valvalue>36.00</valvalue></item><item><title>Consultancy</title><description>Consultancy @ £60 per hour</description><price>60.00</price><qty>2</qty><net>120.00</net><vat_percent>20.00</vat_percent><valvalue>24.00</valvalue></item><item><title>Consultancy</title><description>Help with accounts development</description><price>300.00</price><qty>1</qty><net>300.00</net><vat_percent>20.00</vat_percent><valvalue>60.00</valvalue></item></line_items></invoice></freeplusinvoice>
EOD

$Buffer =~ s/\xc2//g;

$Invitems = '';

while ($Buffer =~ s/<freeplusinvoice>(.*?)<\/freeplusinvoice>/&process_group($1,'header','invoice')/seig) {}

$FORM{invitems} = $Invitems;

while (($Key,$Value) = each %FORM) {
	print "$Key = $Value\n";
}
exit;

sub process_group {

#  To process contiguous groups of items

	my $Invoice = $_[0];
	for ($i=1; $i<3; $i++) {
		$Header = $_[$i];
		while ($Invoice =~ s/<$_[$i]>(.*?)<\/$_[$i]>/&process_set($1)/seig) {}
	}
	return '';
}

sub process_set {

#  To process a single set of multiple fields

	my $Invoice = $_[0];
print "\n<==  $Header  ==>\n\n";
	while ($Invoice =~ s/<(\w+)?>(.*?)<\/\1?>/&process_field($1,$2)/seig) {}
	return '';
}

sub process_field {

#  To process a single field

	$Field = $_[0];
	$Data = $_[1];
	if ($Field =~ /line_items/i) {
		$Header = 'item';
		$Tab = "\t";
		while ($Data =~ s/<item>(.*?)<\/item>/&process_set($1)/seig) {}
		$Invitems .= "  </tr>\n";
		$Header = '';
		$Tab = "";
	}
	else {
		if ($Header =~ /item/i) {
			if ($Field =~ /title/i) {
				if ($Invitems) {
					$Invitems .= "  </tr>\n  <tr>\n";
				}
				else {
					$Invitems .= "\n  <tr>\n";
				}
			}
			else {
				$Invitems .= "    <td>$Data</td>\n";
			}
		}
		else {
			$FORM{$Field} = $Data;
		}
	}
	return '';
}
#while (($Key,$Value) = each %FORM) {
#	print EMAIL "\t$Key\t=\t$Value\n";
#}

#close(EMAIL);

#use DBI;
#$dbh = DBI->connect("DBI:mysql:fpa");

