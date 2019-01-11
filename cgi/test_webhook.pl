#!/usr/bin/perl

#  This process creates an invoice and increments the subdue field by 1 month for each 'withdrawn' API update
#  received.  We receive a 'witdrawn' update when the money is about to be placed in our bank account.
#
#  We can safely ignore any cancelled subscriptions because the sub will effectively lapse if the subdue field
#  has not been updated.

###############  GoCardless API V2  #######################
#
#  We are interssted in 2 types of event:-
#
#  1.  Payment Created (payment_created)  (at which point we need to store the Payment ID against the Subscription
#  2.  Payment Confirmed (confirmed) at which point we get the acct_id of the subscription from gcls using payment ID
#

################ read(STDIN, $Buffer, $ENV{'CONTENT_LENGTH'});

while (<>) {
	$Buffer .= $_;
}

print "Content-Type: text/plain\n";
print "Status 200 OK\n\n";

#while ( ($key, $value) = each %ENV )
#{
#  $Headers .=  "key: $key, value: $ENV{$key}\n";
#}

$Now = `date`;

use JSON;
$json = JSON->new->allow_nonref;

$events_scalar = $json->decode( $Buffer );
$PP =  $json->pretty->encode( $events_scalar );

chomp($Now);

open(FILE,'>>/tmp/gcl2.txt');

print FILE<<EOD;

============== $Now (sandbox)n ==================
$PP
EOD

close(FILE);

#use JSON;
use DBI;
use MIME::Base64;

require "/usr/local/git/fpa/cgi/pdf_sub_invoice.ph";

$dbh = DBI->connect("DBI:mysql:fpa3");

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
my $Events_summary = "Status\t\tAction\t\tSub\t\t\tPayment\n";
$Events_summary .=   "======\t\t======\t\t=========\t========\n";

#$json = JSON->new->allow_nonref;
#$events_scalar = $json->decode($Buffer);
$Events = $events_scalar->{events};
for $Event ( @{$Events} ) {
	if ($Event->{'resource_type'} =~ /subscriptions/ && $Event->{'action'} =~ /payment_created/i) {

#  Find the gcl record for this subscription and update the payment ID

		$Sts = $dbh->do("update companies set compayref='$Event->{links}->{payment}' where comsubref='$Event->{links}->{subscription}'");
		$Events_summary .= "$Sts\t\tCreated\t\t$Event->{links}->{subscription}\t\t$Event->{links}->{payment}\n";
	} elsif ($Event->{'resource_type'} =~ /payments/ && $Event->{'action'} =~ /confirmed/i) {

		$Event->{created_at} =~ s/T.*//;
		$Sts = $dbh->do("update companies set comsubdue=date_add('$Event->{created_at}',interval 1 month) where compayref='$Event->{links}->{payment}'");
		$Events_summary .= "$Sts\t\tSubmitted\t$Event->{links}->{subscription}\t\t$Event->{links}->{payment}\n";
		if ($Sts > 0) {

#  Add a subscription invoice

	                $Companies = $dbh->prepare("select reg_id,id,comsublevel,comname,comaddress,compostcode,regemail,date_format('$Event->{created_at}','%D %M %Y') as datepaid from companies left join registrations using (reg_id) where compayref='$Event->{links}->{payment}'");
        	        $Companies->execute;
                	$Company = $Companies->fetchrow_hashref;
	                $Companies->finish;

        	        $Sts = $dbh->do("insert into subscriptions (acct_id,subdateraised,subinvoiceno,subdescription,subnet,subvat,subfee,subauthcode,substatus,submerchantref,subdatepaid) values ('$Company->{reg_id}+$Company->{id}','$Event->{created_at}','$Subinvno','$Sub_name[$Company->{comsublevel}]','$Sub_amt[$Company->{comsublevel}]','$Sub_vat[$Company->{comsublevel}]','','$Event->{links}->{payment}','Paid','$Event->{id}','$Event->{created_at}')");

                	$Email_msg = sprintf<<EOD;
FreePlus Accounts Invoice/Receipt
=================================

Thank you, your subscription has been successfully processed.

Subscription Details
====================

  Subscription:  $Sub_name[$Company->{comsublevel}]

    Invoice No:  $Subinvno
     Date Paid:  $Company->{datepaid}
        Amount:  $Sub_amt[$Company->{comsublevel}]
           VAT:  $Sub_vat[$Company->{comsublevel}]
     Reference:  $Event->{links}->{payment}

Your invoice is attached to this email message and may also be accessed by logging in to FreePlus Accounts and selecting 'Admin' -> 'My Account'
EOD

	                $Inv_invoice_no = $Subinvno;
        	        $Subinvno++;
                	$Inv_date = $Company->{datepaid};
	                $Inv_desc = $Sub_name[$Company->{comsublevel}];
        	        $Inv_authcode = $Event->{links}->{payment};
                	$Inv_address = $Company->{comname}."\n".$Company->{comaddress}."  ".$Company->{compostcode};
	                $Inv_net = $Sub_amt[$Company->{comsublevel}];
        	        $Inv_vat = $Sub_vat[$Company->{comsublevel}];
                	$Inv_status = "Paid";
	                &send_email();
		}
        }
}
print<<EOD;
Content-Type: text/plain
Status: 200 OK


EOD

open(DOUGMAIL,"| /usr/sbin/sendmail -t");
print DOUGMAIL<<EOD;
From: FreePlus Accounts <fpainvoices\@corunna.com>
To: doug.conran\@corunna.com
Subject: GoCardless Webhook Summary

Event Summary:-

$Events_summary

=================  JSON  ============
$Buffer
EOD
close(DOUGMAIL);

exit;
sub send_email {
        ($PDF_data) = &pdf_invoice();

        $Encoded_msg = encode_base64($PDF_data);
# To: $Company->{regemail}

        open(EMAIL,"| /usr/sbin/sendmail -t");
        print EMAIL<<EOD;
From: FreePlus Accounts <fpainvoices\@corunnasystems.co.uk>
To: doug.conran49i\@googlemail.com
Bcc: doug.conran\@corunna.com
Subject: Your FreePlus Subscription Invoice (Test)
Message-Id: <$Event->{links}->{payment}>
MIME-Version: 1.0
Content-Type: multipart/mixed;
        boundary="----=_NextPart_000_001D_01C0B074.94357480"

This is a multi-part message in MIME format.

------=_NextPart_000_001D_01C0B074.94357480
Content-Type: text/plain;
        charset="iso-8859-1"

Message To: $Company->{regemail}
 
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


