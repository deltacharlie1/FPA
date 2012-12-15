#!/usr/bin/perl

#  script to display the main cover sheet updating screen

#  Processing:-
#  1.  Check user is setup to receive mobile invoices
#  2.  Get reg_id,id,vatscheme
#  3.  Get input invoice details
#  4.  See if customer exists and, if so, get id
#  5.  Call process_invoice.ph


read(STDIN, $Buffer, $ENV{'CONTENT_LENGTH'});

$Buffer =~ tr/+/ /;
$Buffer =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C",hex($1))/eg;

# $Buffer = <<EOD;
#<?xml version='1.0' encoding='UTF-8' standalone='yes' ?><freeplusinvoice><header><regmobile>07899988701</regmobile><comname>Corunna Systems Ltd</comname><layout>Invoice1</layout><invoice_count>1</invoice_count></header><invoice><invourref>M00002</invourref><invprintdate>03-Jul-12</invprintdate><invcusname>Air &amp; Cargo Services Ltd</invcusname><invcusaddr>Unit 5 Planet Centre
#Feltham
#Middx</invcusaddr><invcuspostcode>TW14 0LW</invcuspostcode><invcusemail>doug.conran@corunna.com</invcusemail><customer_telephone> </customer_telephone><invcuscontact>Carl Aspital</invcuscontact><invcusref> </invcusref><invcusterms>28 Days</invcusterms><txnamount>276.00</txnamount><invremarks></invremarks><txnmethod>Cash</txnmethod><payment_action>Paid</payment_action><payment_currency>£</payment_currency><invtotal>230.00</invtotal><invvat>46.00</invvat><line_items><item><description>Hosting for 3 months</description><price>230.00</price><qty>1</qty><net>230.00</net><vat_percent>20.00</vat_percent><vat_value>46.00</vat_value></item></line_items></invoice></freeplusinvoice>
#EOD

$Buffer =~ s/\xc2//g;

# warn $Buffer."\n";

#  Get rid of the freeplus xml tag

$Buffer =~ s/^.*<freeplusinvoice>(.*?)<\/freeplusinvoice>/$1/;


#  Extract the header info into the HEADER hash array

while ($Buffer =~ s/<header>(.*?)<\/header>/&process_set($1,\%HEADER)/sei) {}

#  Check to see if we need to go any further - ie is he set up for mobile invoicing

use DBI;
$dbh = DBI->connect("DBI:mysql:fpa3");	#		<===   NOTE!!

$Companies = $dbh->prepare("select reg_id,id,comvatscheme,regemail,regmembership,datediff(comsubdue,now()) as days_left,comyearend from companies left join registrations using (reg_id) where comname='$HEADER{comname}' and regmobile='$HEADER{regmobile}'");
$Companies->execute;

if ($Companies->rows < 1) {
	print<<EOD;
Content-Type: text/plain

Error - You are not set up to receive mobile invoices.
EOD
	$Companies->finish;
	$dbh->disconnect;
	exit;
}
else {

	require "/usr/local/git/fpa/cgi/process_invoice.ph";

#  Get company details

	$Company = $Companies->fetchrow_hashref;
	$Companies->finish;

#  ... and start to process each invoice

	while ($Buffer =~ s/<invoice>(.*?)<\/invoice>/&process_set($1,\%INVOICE)/sei) {
		while (($Key, $Value) = each %INVOICE) {
			$Value =~ s/\&amp;/\&/g;
			$FORM{$Key} = $Value;
		}

#  Construct $FORM{invitems}

		if ($Company->{comvatscheme} =~ /N/i) {
			$FORM{invitems} = <<EOD;
<table id="itemstable" class="items" border="0" cellpadding="0" cellspacing="0" width="610">
    <tr>
      <th width="280">Description</th>
      <th style="text-align: right;" width="50">Unit<br>Price</th>
      <th style="text-align: right;" width="30">Qty</th>
      <th style="text-align: right;" width="50">Sub<br>Total</th>
      <th style="text-align: right;" width="60">Total</th>
      <th style="display:none;"></th>
    </tr>
EOD
		}
		else {
			$FORM{invitems} = <<EOD;
<table id="itemstable" class="items" border="0" cellpadding="0" cellspacing="0" width="610">
    <tr>
      <th width="280">Description</th>
      <th style="text-align: right;" width="50">Unit<br>Price</th>
      <th style="text-align: right;" width="30">Qty</th>
      <th style="text-align: right;" width="50">Sub<br>Total</th>
      <th style="text-align: center;" width="30">VAT<br>Rate</th>
      <th style="text-align: right;" width="40">VAT<br>Amt</th>
      <th style="text-align: right;" width="60">Total</th>
      <th style="display:none;"></th>
    </tr>
EOD
		}

		foreach $Line (@LINES) {
			$FORM{invitems} .= $Line;
		}
		$FORM{invitems} .= "</table>\n";
		$FORM{invitemcount} = $#LINES;

#  Now process the invoice

		$COOKIE->{ACCT} = $Company->{reg_id}.'+'.$Company->{id};
		$COOKIE->{VAT} = $Company->{comvatscheme};
		$COOKIE->{YEAREND} = $Company->{comyearend};

#  See if wwe already have this invoice/quotation

		$MOurref = $FORM{invourref};
		$MOurref =~ s/^\w//;		#  Strip off the M/Q

		$Invoices = $dbh->prepare("select id,invstatuscode,cus_id,invdesc from invoices where acct_id='$COOKIE->{ACCT}' and (invourref='M$MOurref' or invourref='Q$MOurref')");
		$Invoices->execute;
		if ($Invoices->rows > 0) {
			($FORM{id},$Invstatus,$FORM{cus_id},$FORM{invdesc}) = $Invoices->fetchrow;
		}
		else {
			$FORM{id} = 0;
		}
		$Invoices->finish;

#  Do we already have this customer

		unless ($FORM{cus_id}) {
			$Customers = $dbh->prepare("select id from customers where acct_id='$COOKIE-{ACCT}' and cusname='$INVOICE{invcusname}'");
			$Customers->execute;
			$Customer = $Customers->fetchrow_hashref;
			$Customers->finish;
			if ($Customer->{id} > 0) {
				$FORM{cus_id} = $Customer->{id};
			}
			else {
				$FORM{cus_id} = 0;
			}
		}

#  Do we have a special invoice layout

		$FORM{invlayout} = '0';
		if ($HEADER{layout} !~ /Draft|Default/i) {
			$Layouts = $dbh->prepare("select id from invoice_layouts where acct_id='$COOKIE->{ACCT}' and laydesc='$HEADER{layout}'");
			$Layouts->execute;
			$Layout = $Layouts->fetchrow_hashref;
			$Layouts->finish;
			if ($Layout->{id} > 0) {
				$FORM{invlayout} = $Layout->{id};
			}
		}
		$FORM{invtype} = 'S';
		$FORM{invcoa} = '4000';
		$FORM{invcusregion} = 'UK';

		if ($HEADER{layout} =~ /Draft/i) {
			&save_invoice('draft');
		}
		elsif ($FORM{invourref} =~ /^Q/i) {
			&save_invoice('quote');
		}
		else {
			unless ($Invstatus > 1) {
				&save_invoice('final');
			}

#  Is is paid up?

			if ($INVOICE{txnamount} > 0) {

				if ($INVOICE{txnmethod} =~ /Cash/i) {
					$FORM{txnmethod} = '1300';
				}
				elsif ($INVOICE{txnmethod} =~ /Cheq/i) {
					$FORM{txnmethod} = '1310';
				}
				else {
					$FORM{txnmethod} = '1200';
				}

				&money_in();
				&pay_invoice();
			}
		}

		if ($FORM{invcusemail} && $FORM{invcusemail} !~ /none/i) {
			&sendemail();
		}

		print <<EOD;
Content-Type: text/plain

Invoice saved with invoice number $FORM{invinvoiceno}
EOD

		undef %INVOICE;
		undef @LINES;
	}
	$dbh->disconnect;
}

exit;


sub process_set {

#  To process a single set of multiple fields

	my $XMLset = $_[0];
	my $HASH = $_[1];

	while ($XMLset =~ s/<(\w+)?>(.*?)<\/\1?>/&process_field($1,$2,$HASH)/seig) {}
	return '';
}

sub process_field {

#  To process a single field

	$Field = $_[0];
	$Data = $_[1];
	my $HASH = $_[2];
	if ($Field =~ /line_items/i) {
		my %FIELDS;
		my $HTML;
		while ($Data =~ s/<item>(.*?)<\/item>/&process_item($1,\%FIELDS)/sei) {
#			print "\n####  item processing  #####\n\n";

			if ($Company->{comvatscheme} =~ /N/i) {
				$HTML = "    <tr>\n      <td>$FIELDS{description}</td>\n      <td class=\"txtright\">$FIELDS{price}</td>\n      <td class=\"txtright\">$FIELDS{qty}</td>\n      <td class=\"txtright\">$FIELDS{net}</td>\n      <td class=\"txtright\">$FIELDS{net}</td>\n      <td class=\"hidden\"></td>\n    </tr>\n";
			}
			else {
				$FIELDS{vat_percent} =~ s/\.0?0?$//;
				$FIELDS{vat_percent} .= '%';
				my $Total = $FIELDS{net}+$FIELDS{vat_value};
				$HTML = "    <tr>\n      <td>$FIELDS{description}</td>\n      <td class=\"txtright\">$FIELDS{price}</td>\n      <td class=\"txtright\">$FIELDS{qty}</td>\n      <td class=\"txtright\">$FIELDS{net}</td>\n      <td class=\"txtcenter\">$FIELDS{vat_percent}</td>\n      <td class=\"txtright\">$FIELDS{vat_value}</td>\n      <td class=\"txtright\">$Total</td>\n      <td class=\"hidden\"></td>\n    </tr>\n";
			}
			push(@LINES,$HTML);
			undef %FIELDS;
		}
	}
	else {
		$HASH->{$Field} = $Data;
	}
	return '';
}

sub process_item {

#  To process a single set of multiple fields

	my $Invoice = $_[0];
	my $FIELDS = $_[1];
	while ($Invoice =~ s/<(\w+)?>(.*?)<\/\1?>/&process_item_field($1,$2,$FIELDS)/seig) {}
	return '';
}

sub process_item_field {

#  To process a single field

	my $Field = $_[0];
	my $Data = $_[1];
	my $FIELDS = $_[2];
	$FIELDS->{$Field} = $Data;
	return '';
}

sub sendemail {

	use MIME::Base64;

	if ($FORM{invlayout} > 0) {
		require "/usr/local/httpd/cgi-bin/fpa/pdf_layout.ph";
		($PDF_data,$Invoice_no) = &pdf_invoice1($FORM{id},'Y','',$FORM{invlayout},'T');
	}
	else {
		require "/usr/local/httpd/cgi-bin/fpa/pdf_invoice.ph";
		($PDF_data,$Invoice_no) = &pdf_invoice($FORM{id},'Y','',$FORM{invlayout},'T');
	}

        $Encoded_msg = encode_base64($PDF_data);

        open(EMAIL,"| /usr/sbin/sendmail -t");
# To: $FORM{invcusemail}
        print EMAIL<<EOD;
From: $HEADER{comname} <fpainvoices\@corunna.com>
To: doug.conran\@corunna.com
Reply-To: $HEADER{comname} <$Company->{regemail}>
cc: $Company->{regemail}
Subject: Invoice $FORM{invinvoiceno} from $HEADER{comname} is attached
MIME-Version: 1.0
Content-Type: multipart/mixed;
        boundary="----=_NextPart_000_001D_01C0B074.94357480"
Message-Id: <e8258e5140317ff36c7f8225a3bf9590>
From: $HEADER{comname} <$Company->{regemail}> 
X-Priority: 3
X-Mailer: Postfix v2.0
X-MimeOLE: Produced By Microsoft MimeOLE V5.50.4133.2400
X-MSMail-Priority: Normal

This is a multi-part message in MIME format.
 
------=_NextPart_000_001D_01C0B074.94357480
Content-Type: text/plain;
        charset="iso-8859-1"

Invoice $FORM{invinvoiceno} from $HEADER{comname} is attached to this email as a pdf attachment.

This invoice is being emailed to you from the FreePlus Accounts Mobile Invoicing application.  To find out more about this please go to http://www.freeplusaccounts.co.uk


------=_NextPart_000_001D_01C0B074.94357480
Content-Type: application/pdf;
        name="$FORM{invinvoiceno}.pdf"
Content-Transfer-Encoding: base64
Content-Disposition: attachment;
        filename="$FORM{invinvoiceno}.pdf"

$Encoded_msg 

------=_NextPart_000_001D_01C0B074.94357480--

EOD
        close(EMAIL);
}

