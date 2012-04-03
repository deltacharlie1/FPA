#!/usr/bin/perl

read(STDIN, $Buffer, $ENV{'CONTENT_LENGTH'});

$Buffer = <<EOD;
{
  "payload": {
    "bills": [
      {
        "id": "020YADXY99",
        "status": "paid",
        "uri": "https://sandbox.gocardless.com/api/v1/bills/020YADXY99",
        "source_type": "subscription",
        "source_id": "0265CVX1E7",
        "paid_at": "2012-04-03T15:00:46Z",
        "payment_id": "022FERM4KV"
      }
    ],
    "action": "paid",
    "resource_type": "bill",
    "signature": "9e72a82977e7761e563e952c29df8cb8031fd5c7ccebf6d075993dd08769e6d7"
  }
}
EOD

use JSON;
use DBI;
$dbh = DBI->connect("DBI:mysql:fpa");

$Payload = decode_json($Buffer);

if ($Payload->{payload}->{action} =~ /paid/i && $Payload->{payload}->{resource_type} =~ /bill/i) {

        foreach $bill (@{$Payload->{payload}->{bills}}) {
		if ($bill->{source_type} =~ /subscription/i) {
			$Sts = $dbh->do("update companies set comsubdue=date_add(comsubdue,interval 1 month) where comsubref='$bill->{source_id}'");
		}
        }
}
print<<EOD;
Content-Type: text/plain
Status: 200 OK


EOD


exit;
