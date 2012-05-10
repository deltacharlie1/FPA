#!/usr/bin/perl

read(STDIN, $Buffer, $ENV{'CONTENT_LENGTH'});

print<<EOD;
Content-Type: text/plain
Status: 200 OK

EOD

warn "Webhook - \n$Buffer\n";
exit;

use JSON;
use DBI;
use MIME::Base64;

require "/usr/local/git/fpa/cgi/pdf_sub_invoice.ph";

$dbh = DBI->connect("DBI:mysql:fpa");

#  Get the last invoice no

$Subs = $dbh->prepare("select subinvoiceno from subscriptions order by id desc limit 1");
$Subs->execute;
@Sub = $Subs->fetchrow;
$Subs->finish;
$Subinvno = $Sub[0] + 1;

$Buffer = <<EOD;
{
  "payload": {
    "subscriptions": [
      {
        "id": "12345",
        "status": "cancelled",
        "uri": "https://sandbox.gocardless.com/api/v1/subscriptions/"
      }
    ],
    "action": "cancelled",
    "resource_type": "subscription",
    "signature": "9efed99e556d231e960a1e7c1a428987195bd0f96bfcc63c29ead45843257c44"
  }
}
EOD
$Buffer = <<EOD;
{
  "payload": {
    "bills": [
      {
        "id": "02N6EEHH34",
        "status": "paid",
        "uri": "https://sandbox.gocardless.com/api/v1/bills/02N6EEHH34",
        "source_type": "subscription",
        "source_id": "02G3Q6PBCF",
        "paid_at": "2012-04-26T18:17:43Z",
        "payment_id": 64
      }
    ],
    "action": "paid",
    "resource_type": "bill",
    "signature": "5229705c6a48763abb8b9d61b93eb3f602ce178933d66aa0ee2c8f6c94b68fe4"
  }
}
EOD

# warn "Webhook - Buffer = $Buffer\n";

@Sub_name = ("FreePlus Free Edition","Bookkeeper Basic","FreePlus Standard","Bookkeeper Standard","FreePlus Premium","Bookkeeper Premium");
@Sub_amt = ("0.00","5.00","5.00","10.00","10.00","20.00");
@Sub_vat = ("0.00","1.00","1.00","2.00","2.00","4.00");

$Payload = decode_json($Buffer);

if ($Payload->{payload}->{action} =~ /paid/i && $Payload->{payload}->{resource_type} =~ /bill/i) {

       foreach $bill (@{$Payload->{payload}->{bills}}) {
		if ($bill->{source_type} =~ /subscription/i) {
#			$Sts = $dbh->do("update companies set comsubdue=date_add(comsubdue,interval 1 month) where comsubref='$bill->{source_id}'");
# 			warn "Webhook - \$Sts = \$dbh->do(\"update companies set comsubdue=date_add(comsubdue,interval 1 month) where comsubref='$bill->{source_id}'\")\n";

			$bill->{paid_at} =~ s/T*$//;

#  Get various company details

			$Companies = $dbh->prepare("select reg_id,id,comsublevel,comname,comaddress,compostcode,regemail,date_format('$bill->{paid_at}','%D %M %Y') as datepaid from companies left join registrations using (reg_id) where comsubref='$bill->{source_id}'");
			$Companies->execute;
			$Company = $Companies->fetchrow_hashref;
			$Companies->finish;

#			$Sts = $dbh->do("insert into subscriptions (acct_id,subdateraised,subinvoiceno,subdescription,subnet,subvat,subauthcode,substatus,submerchantref,subdatepaid) values ('$Company->{reg_id}+$Company->{id}','$bill->{paid_at}','$Subinvno','$Sub_name[$Company->{comsublevel}]','$Sub_amt[$Company->{comsublevel}]','$Sub_vat[$Company->{comsublevel}]','$bill->{id}','Paid','$bill->{source_id}','$bill->{paid_at}')");

			$Email_msg = sprintf<<EOD;
FreePlus Accounts Invoice/Receipt
=================================

Thank you, your subscription has been successfully processed.

Subscription Details
====================

  Subscription: $Sub_name[$Company->{comsublevel}]

  Invoice No:  $Subinvno
   Date Paid:  $Company->{datepaid}
      Amount:  $Sub_amt[$Company->{comsublevel}]
         VAT:  $Sub_vat[$Company->{comsublevel}]
   Reference:  $bill->{id}

Your invoice is attached to this email message and may also be accessed by logging in to FreePlus Accounts and selecting 'Admin' -> 'My Account'
EOD

			$Inv_invoice_no = $Subinvno;
			$Subinvno++;
			$Inv_date = $Company->{datepaid};
			$Inv_desc = $Sub_name[$Company->{comsublevel}];
			$Inv_authcode = $bill->{id};
			$Inv_address = $Company->{comname}."\n".$Company->{comaddress}."  ".$Company->{compostcode};
			$Inv_net = $Sub_amt[$Company->{comsublevel}];
			$Inv_vat = $Sub_vat[$Company->{comsublevel}];
			$Inv_status = "Paid";
			&send_email();
		}
        }
}
$dbh->disconnect;

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
From: FreePlus Accounts <fpainvoices\@corunna.com>
Bcc: doug.conran\@corunna.com
Subject: Your FreePlus Subscription Invoice
MIME-Version: 1.0
Content-Type: multipart/mixed;
        boundary="----=_NextPart_000_001D_01C0B074.94357480"
Message-Id: <$bill->{id}>
From: FreePlus Accounts <fpainvoices\@corunna.com>
X-Priority: 3
X-Mailer: Postfix v2.0
X-MimeOLE: Produced By Microsoft MimeOLE V5.50.4133.2400
X-MSMail-Priority: Normal

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
}


