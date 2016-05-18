#!/usr/bin/perl

#  This process creates an invoice and increments the subdue field by 1 month for each 'withdrawn' API update
#  received.  We receive a 'witdrawn' update when the money is about to be placed in our bank account.
#
#  We can safely ignore any cancelled subscriptions because the sub will effectively lapse if the subdue field
#  has not been updated.

read(STDIN, $Buffer, $ENV{'CONTENT_LENGTH'});

use JSON;
use DBI;
use MIME::Base64;

require "/usr/local/git/fpa/cgi/pdf_sub_invoice.ph";

$dbh = DBI->connect("DBI:mysql:fpa");

$Today = `date +%Y-%m-%d`;
chomp($Today);

#  Get the last invoice no

$Subs = $dbh->prepare("select subinvoiceno from subscriptions order by id desc limit 1");
$Subs->execute;
@Sub = $Subs->fetchrow;
$Subs->finish;
$Subinvno = $Sub[0] + 1;
$Pound = chr(163);

@Sub_name = ("FreePlus Free Edition \@ FREE","FreePlus Bookkeeper Basic \@ ${Pound}5.00pm","FreePlus Standard \@ ${Pound}5.00pm","FreePlus Bookkeeper Standard \@ ${Pound}10.00pm","FreePlus Premium \@ ${Pound}10.00pm","FreePlus Bookkeeper Premium \@ ${Pound}20.00pm");
@Sub_amt = ("0.00","5.00","5.00","10.00","10.00","20.00");
@Sub_vat = ("0.00","1.00","1.00","2.00","2.00","4.00");

$Payload = decode_json($Buffer);

if ($Payload->{payload}->{action} =~ /paid/i && $Payload->{payload}->{resource_type} =~ /bill/i) {

        foreach $bill (@{$Payload->{payload}->{bills}}) {
		if ($bill->{source_type} =~ /subscription/i) {
			$Sts = $dbh->do("update companies set comsubdue=date_add(comsubdue,interval 1 month) where comsubref='$bill->{source_id}'");

			$bill->{paid_at} = $bill->{paid_at} || $Today;

                        $bill->{paid_at} =~ s/T*$//;

#  Calculate the Net and VAT

			$Net = sprintf('%1.2f',($bill->{amount} * 100) / 120);
			$Vat = sprintf('%1.2f',$bill->{amount} - $Net);
			$Fee = sprintf('%1.2f',$bill->{amount} - $bill->{amount_minus_fees});

#  Add a subscription invoice

                        $Companies = $dbh->prepare("select reg_id,id,comsublevel,comname,comaddress,compostcode,regemail,date_format('$bill->{paid_at}','%D %M %Y') as datepaid from companies left join registrations using (reg_id) where comsubref='$bill->{source_id}'");
                        $Companies->execute;
                        $Company = $Companies->fetchrow_hashref;
                        $Companies->finish;

                        $Sts = $dbh->do("insert into subscriptions (acct_id,subdateraised,subinvoiceno,subdescription,subnet,subvat,subfee,subauthcode,substatus,submerchantref,subdatepaid) values ('$Company->{reg_id}+$Company->{id}','$bill->{paid_at}','$Subinvno','$Sub_name[$Company->{comsublevel}]','$Net','$Vat','$Fee','$bill->{id}','Paid','$bill->{source_id}','$bill->{paid_at}')");

                        $Email_msg = sprintf<<EOD;
FreePlus Accounts Invoice/Receipt
=================================

Thank you, your subscription has been successfully processed.

Subscription Details
====================

  Subscription:  $Sub_name[$Company->{comsublevel}]

    Invoice No:  $Subinvno
     Date Paid:  $Company->{datepaid}
        Amount:  $Net
           VAT:  $Vat
     Reference:  $bill->{id}

Your invoice is attached to this email message and may also be accessed by logging in to FreePlus Accounts and selecting 'Admin' -> 'My Account'
EOD

                        $Inv_invoice_no = $Subinvno;
                        $Subinvno++;
                        $Inv_date = $Company->{datepaid};
                        $Inv_desc = $Sub_name[$Company->{comsublevel}];
                        $Inv_authcode = $bill->{id};
                        $Inv_address = $Company->{comname}."\n".$Company->{comaddress}."  ".$Company->{compostcode};
                        $Inv_net = $Net;
                        $Inv_vat = $Vat;
                        $Inv_status = "Paid";
                        &send_email();

		}
        }
}
print<<EOD;
Content-Type: text/plain
Status: 200 OK


EOD

exit;
sub send_email {
        ($PDF_data) = &pdf_invoice();

        $Encoded_msg = encode_base64($PDF_data);

        open(EMAIL,"| /usr/sbin/sendmail -t");
        print EMAIL<<EOD;
From: FreePlus Accounts <fpainvoices\@corunnasystems.co.uk>
To: $Company->{regemail}
Bcc: doug.conran\@corunna.com
Subject: Your FreePlus Subscription Invoice
Message-Id: <$bill->{id}>
MIME-Version: 1.0
Content-Type: multipart/mixed;
        boundary="----=_NextPart_000_001D_01C0B074.94357480"

This is a multi-part message in MIME format.

------=_NextPart_000_001D_01C0B074.94357480
Content-Type: text/plain;
        charset="iso-8859-1"

$Email_msg

EOD

        unless ($Inv_status =~ /No Invoice/i) {

                print EMAIL<<EOD;
------=_NextPart_000_001D_01C0B074.94357480
Content-Type: application/pdf;
        name="$Inv_invoice_no.pdf"
Content-Transfer-Encoding: base64
Content-Disposition: attachment;
        filename="$Inv_invoice_no.pdf"

$Encoded_msg

EOD
        }
        print EMAIL<<EOD;
------=_NextPart_000_001D_01C0B074.94357480--

EOD
        close(EMAIL);

        open(DOUGMAIL,"| /usr/sbin/sendmail -t");
        print DOUGMAIL<<EOD;
From: FreePlus Accounts <fpainvoices\@corunna.com>
To: doug.conran\@corunna.com
Subject: JSON subscription

$Buffer
EOD
close(DOUGMAIL);
}


