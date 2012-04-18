#!/usr/bin/perl

read(STDIN, $Buffer, $ENV{'CONTENT_LENGTH'});

use JSON;
use DBI;
$dbh = DBI->connect("DBI:mysql:fpa");

@Sub_name = ("FreePlus Free Edition","Bookkeeper Basic","FreePlus Standard","Bookkeeper Standard","FreePlus Premium","Bookkeeper Premium");
@Sub_amt = ("0.00","5.00","5.00","10.00","10.00","20.00");
@Sub_vat = ("0.00","1.00","1.00","2.00","2.00","4.00");

$Payload = decode_json($Buffer);

if ($Payload->{payload}->{action} =~ /paid/i && $Payload->{payload}->{resource_type} =~ /bill/i) {

        foreach $bill (@{$Payload->{payload}->{bills}}) {
		if ($bill->{source_type} =~ /subscription/i) {
			$Sts = $dbh->do("update companies set comsubdue=date_add(comsubdue,interval 1 month) where comsubref='$bill->{source_id}'");

#  Add a subscription invoice

                        $Companies = $dbh->prepare("select reg_id,id,comsublevel from companies where comsubref='$bill->{source_id}'");
                        $Companies->execute;
                        $Company = $Companies->fetchrow_hashref;
                        $Companies->finish;

                        $bill->{paid_at} =~ s/T*$//;

                        $Sts = $dbh->do("insert into subscriptions (acct_id,subdateraised,subinvoiceno,subdescription,subnet,subvat,subauthcode,substatus,submerchantref,subdatepaid) values ('$Company->{reg_id}+$Company->{id}','$bill->{paid_at}','$bill->{id}','$Sub_name[$Company->{comsublevel}]','$Sub_amt[$Company->{comsublevel}]','$Sub_vat[$Company->{comsublevel}]','$bill->{id}','Paid','$bill->{source_id}','$bill->{paid_at}')");

		}
        }
}
print<<EOD;
Content-Type: text/plain
Status: 200 OK


EOD

exit;
