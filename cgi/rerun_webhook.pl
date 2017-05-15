#!/usr/bin/perl

#  This process creates an invoice and increments the subdue field by 1 month for each 'withdrawn' API update
#  received.  We receive a 'witdrawn' update when the money is about to be placed in our bank account.
#
#  We can safely ignore any cancelled subscriptions because the sub will effectively lapse if the subdue field
#  has not been updated.

use JSON;
use DBI;
use MIME::Base64;

require "/usr/local/git/fpa/cgi/pdf_sub_invoice.ph";

$dbh = DBI->connect("DBI:mysql:fpa3);

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

$Buffer = sprintf<<EOD;
[{"id":"PM000BDRW6YQYB","amount":"6.0","amount_minus_fees":"5.94","gocardless_fees":"0.06","partner_fees":"0.0","currency":"GBP","name":"FreePlus Standard","status":"paid","description":null,"created_at":"2016-05-19T04:31:02Z","merchant_id":"0265HC17QC","user_id":"CU0001ZWTAWKJ2","paid_at":"2016-05-25T10:31:28Z","source_type":"subscription","source_id":"SB0000594YHD46","uri":"https://gocardless.com/api/v1/bills/PM000BDRW6YQYB","can_be_retried":null,"can_be_cancelled":null,"payout_id":null,"is_setup_fee":false,"charge_customer_at":"2016-05-24"},{"id":"PM000BBAPE2T5F","amount":"6.0","amount_minus_fees":"5.94","gocardless_fees":"0.06","partner_fees":"0.0","currency":"GBP","name":"FreePlus Standard","status":"withdrawn","description":null,"created_at":"2016-05-17T04:30:45Z","merchant_id":"0265HC17QC","user_id":"0M43R778ZA","paid_at":"2016-05-23T10:13:02Z","source_type":"subscription","source_id":"0M43DZ5SF8","uri":"https://gocardless.com/api/v1/bills/PM000BBAPE2T5F","can_be_retried":null,"can_be_cancelled":null,"payout_id":"PO0001B5Q530A7","is_setup_fee":false,"charge_customer_at":"2016-05-20"},{"id":"PM000BBAP500RD","amount":"6.0","amount_minus_fees":"5.94","gocardless_fees":"0.06","partner_fees":"0.0","currency":"GBP","name":"FreePlus Standard","status":"withdrawn","description":null,"created_at":"2016-05-17T04:30:45Z","merchant_id":"0265HC17QC","user_id":"0BW20D716M","paid_at":"2016-05-23T10:13:02Z","source_type":"subscription","source_id":"0M42XW1MFF","uri":"https://gocardless.com/api/v1/bills/PM000BBAP500RD","can_be_retried":null,"can_be_cancelled":null,"payout_id":"PO0001B5Q530A7","is_setup_fee":false,"charge_customer_at":"2016-05-20"},{"id":"PM000BB9QRTY9P","amount":"6.0","amount_minus_fees":"5.94","gocardless_fees":"0.06","partner_fees":"0.0","currency":"GBP","name":"FreePlus Standard","status":"withdrawn","description":null,"created_at":"2016-05-17T04:30:24Z","merchant_id":"0265HC17QC","user_id":"0558N8V38K","paid_at":"2016-05-23T10:12:34Z","source_type":"subscription","source_id":"05589JECVN","uri":"https://gocardless.com/api/v1/bills/PM000BB9QRTY9P","can_be_retried":null,"can_be_cancelled":null,"payout_id":"PO0001B5Q530A7","is_setup_fee":false,"charge_customer_at":"2016-05-20"},{"id":"PM000BAEZMJXG0","amount":"6.0","amount_minus_fees":"5.94","gocardless_fees":"0.06","partner_fees":"0.0","currency":"GBP","name":"FreePlus Standard","status":"withdrawn","description":null,"created_at":"2016-05-16T04:31:11Z","merchant_id":"0265HC17QC","user_id":"CU0001P63Y6R2C","paid_at":"2016-05-20T10:14:25Z","source_type":"subscription","source_id":"12CMF0M1K3","uri":"https://gocardless.com/api/v1/bills/PM000BAEZMJXG0","can_be_retried":null,"can_be_cancelled":null,"payout_id":"PO0001B1SKF9Y5","is_setup_fee":false,"charge_customer_at":"2016-05-19"},{"id":"PM000B83RP3HM1","amount":"6.0","amount_minus_fees":"5.94","gocardless_fees":"0.06","partner_fees":"0.0","currency":"GBP","name":"FreePlus Standard","status":"withdrawn","description":null,"created_at":"2016-05-13T04:31:24Z","merchant_id":"0265HC17QC","user_id":"0Y1XWZY88Q","paid_at":"2016-05-19T12:27:48Z","source_type":"subscription","source_id":"0Y1XRNB97V","uri":"https://gocardless.com/api/v1/bills/PM000B83RP3HM1","can_be_retried":null,"can_be_cancelled":null,"payout_id":"PO0001AY0T8WEN","is_setup_fee":false,"charge_customer_at":"2016-05-18"},{"id":"PM000B60HFSPM0","amount":"6.0","amount_minus_fees":"5.94","gocardless_fees":"0.06","partner_fees":"0.0","currency":"GBP","name":"FreePlus Standard","status":"withdrawn","description":null,"created_at":"2016-05-11T04:40:21Z","merchant_id":"0265HC17QC","user_id":"0MPX482GP0","paid_at":"2016-05-17T10:26:02Z","source_type":"subscription","source_id":"0MPXY5WDW2","uri":"https://gocardless.com/api/v1/bills/PM000B60HFSPM0","can_be_retried":null,"can_be_cancelled":null,"payout_id":"PO0001AME1SWE2","is_setup_fee":false,"charge_customer_at":"2016-05-16"},{"id":"PM000B5NYGRYCW","amount":"6.0","amount_minus_fees":"5.94","gocardless_fees":"0.06","partner_fees":"0.0","currency":"GBP","name":"FreePlus Standard","status":"withdrawn","description":null,"created_at":"2016-05-11T04:35:46Z","merchant_id":"0265HC17QC","user_id":"CU0001T5AC13BG","paid_at":"2016-05-17T10:20:50Z","source_type":"subscription","source_id":"MD0001DK0JCCWX","uri":"https://gocardless.com/api/v1/bills/PM000B5NYGRYCW","can_be_retried":null,"can_be_cancelled":null,"payout_id":"PO0001AME1SWE2","is_setup_fee":false,"charge_customer_at":"2016-05-16"},{"id":"PM000B5NEDCXAR","amount":"6.0","amount_minus_fees":"5.94","gocardless_fees":"0.06","partner_fees":"0.0","currency":"GBP","name":"FreePlus Standard","status":"withdrawn","description":null,"created_at":"2016-05-11T04:35:35Z","merchant_id":"0265HC17QC","user_id":"0NDXM5JD7Y","paid_at":"2016-05-17T10:20:35Z","source_type":"subscription","source_id":"0NDXS5WN34","uri":"https://gocardless.com/api/v1/bills/PM000B5NEDCXAR","can_be_retried":null,"can_be_cancelled":null,"payout_id":"PO0001AME1SWE2","is_setup_fee":false,"charge_customer_at":"2016-05-16"},{"id":"PM000B5M5T6J9Y","amount":"6.0","amount_minus_fees":"5.94","gocardless_fees":"0.06","partner_fees":"0.0","currency":"GBP","name":"FreePlus Standard","status":"withdrawn","description":null,"created_at":"2016-05-11T04:35:09Z","merchant_id":"0265HC17QC","user_id":"0HXHRDFPVJ","paid_at":"2016-05-17T10:19:58Z","source_type":"subscription","source_id":"0HXHXCPDCX","uri":"https://gocardless.com/api/v1/bills/PM000B5M5T6J9Y","can_be_retried":null,"can_be_cancelled":null,"payout_id":"PO0001AME1SWE2","is_setup_fee":false,"charge_customer_at":"2016-05-16"},{"id":"PM000B5JVR5S8R","amount":"6.0","amount_minus_fees":"5.94","gocardless_fees":"0.06","partner_fees":"0.0","currency":"GBP","name":"FreePlus Standard","status":"withdrawn","description":null,"created_at":"2016-05-11T04:34:40Z","merchant_id":"0265HC17QC","user_id":"05SQV0F1MG","paid_at":"2016-05-17T10:19:20Z","source_type":"subscription","source_id":"05SQRW5PE1","uri":"https://gocardless.com/api/v1/bills/PM000B5JVR5S8R","can_be_retried":null,"can_be_cancelled":null,"payout_id":"PO0001AME1SWE2","is_setup_fee":false,"charge_customer_at":"2016-05-16"},{"id":"PM000B498QVYTE","amount":"6.0","amount_minus_fees":"5.94","gocardless_fees":"0.06","partner_fees":"0.0","currency":"GBP","name":"FreePlus Standard","status":"withdrawn","description":null,"created_at":"2016-05-10T04:30:34Z","merchant_id":"0265HC17QC","user_id":"0KYGKWWSZX","paid_at":"2016-05-16T10:13:49Z","source_type":"subscription","source_id":"0KYGQ4V4GE","uri":"https://gocardless.com/api/v1/bills/PM000B498QVYTE","can_be_retried":null,"can_be_cancelled":null,"payout_id":"PO0001AFPGC9R1","is_setup_fee":false,"charge_customer_at":"2016-05-13"},{"id":"PM000B3BPP55P2","amount":"6.0","amount_minus_fees":"5.94","gocardless_fees":"0.06","partner_fees":"0.0","currency":"GBP","name":"FreePlus Standard","status":"withdrawn","description":null,"created_at":"2016-05-09T04:30:38Z","merchant_id":"0265HC17QC","user_id":"0NBPAACN6E","paid_at":"2016-05-13T10:12:51Z","source_type":"subscription","source_id":"0NBPWK0W85","uri":"https://gocardless.com/api/v1/bills/PM000B3BPP55P2","can_be_retried":null,"can_be_cancelled":null,"payout_id":"PO0001ABKWZ5N5","is_setup_fee":false,"charge_customer_at":"2016-05-12"}]
EOD

$Payload = decode_json($Buffer);

        foreach $bill (@{$Payload}) {
		if ($bill->{source_type} =~ /subscription/i) {

			$bill->{paid_at} = $bill->{paid_at} || $Today;
                        $bill->{paid_at} =~ s/T.*$//;
			$Sts = $dbh->do("update companies set comsubdue=date_add('$bill->{paid_at}',interval 37 day) where comsubref='$bill->{source_id}'");

#  Calculate the Net and VAT

			$Net = sprintf('%1.2f',($bill->{amount} * 100) / 120);
			$Vat = sprintf('%1.2f',$bill->{amount} - $Net);
			$Fee = sprintf('%1.2f',$bill->{amount} - $bill->{amount_minus_fees});

#  Add a subscription invoice

                        $Companies = $dbh->prepare("select reg_id,id,comsublevel,comname,comaddress,compostcode,regemail,date_format('$bill->{paid_at}','%D %M %Y') as datepaid from companies left join registrations using (reg_id) where comsubref='$bill->{source_id}'");
                        $Companies->execute;
                        if ($Company = $Companies->fetchrow_hashref) {
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
			}
                        $Companies->finish;

        }
}
print<<EOD;
Content-Type: text/plain
Status: 200 OK


EOD

exit;

