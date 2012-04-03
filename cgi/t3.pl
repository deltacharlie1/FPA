#!/usr/bin/perl

use JSON;

$Data = <<EOD;
{
  "payload": {
    "bills": [
      {
        "id": "123456",
        "status": "paid",
        "uri": "https://sandbox.gocardless.com/api/v1/bills/123456",
        "source_type": "subscription",
        "source_id": "sub4321",
        "paid_at": "2012-04-01T13:48:48Z",
        "payment_id": 49
      },
      {
        "id": "456356",
        "status": "paid",
        "uri": "https://sandbox.gocardless.com/api/v1/bills/123456",
        "source_type": "subscription",
        "source_id": "sub15576",
        "paid_at": "2012-04-01T13:48:48Z",
        "payment_id": 59
      },
      {
        "id": "hytfgt",
        "status": "paid",
        "uri": "https://sandbox.gocardless.com/api/v1/bills/123456",
        "source_type": "subscription",
        "source_id": "22dwse1",
        "paid_at": "2012-04-01T13:48:48Z",
        "payment_id": 69
      }
    ],
    "action": "paid",
    "resource_type": "bill",
    "signature": "f556ef496a3f8e4e7821d2617f344fae8cec3df513f5ad80e2a362c888a078ee"
  }
}
EOD
$Payload = decode_json($Data);

if ($Payload->{payload}->{action} =~ /paid/i && $Payload->{payload}->{resource_type} =~ /bill/i) { 
	print "len = ".@{$Payload->{payload}->{bills}}."\n\n";

	foreach $bill (@{$Payload->{payload}->{bills}}) {
		print "$bill->{id} / $bill->{source_id}\n";
	}
}	
