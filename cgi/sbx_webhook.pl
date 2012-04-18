#!/usr/bin/perl

read(STDIN, $Buffer, $ENV{'CONTENT_LENGTH'});

use JSON;
use DBI;
$dbh = DBI->connect("DBI:mysql:fpa");

$Buffer = <<EOD;
{
  "payload": {
    "bills": [
      {
        "id": "12345",
        "status": "paid",
        "uri": "https://sandbox.gocardless.com/api/v1/bills/12345",
        "source_type": "subscription",
        "source_id": "abcde",
        "paid_at": "2012-04-18T14:48:02Z",
        "payment_id": 24
      }
    ],
    "action": "paid",
    "resource_type": "bill",
    "signature": "8fea9e5567c80f0eea36d728b02d38b4692a6b1b945f6164ff4dc07eef7eb8f3"
  }
}
EOD

warn "Webhook - Buffer = $Buffer\n";

$Payload = decode_json($Buffer);

if ($Payload->{payload}->{action} =~ /paid/i && $Payload->{payload}->{resource_type} =~ /bill/i) {

        foreach $bill (@{$Payload->{payload}->{bills}}) {
		if ($bill->{source_type} =~ /subscription/i) {
			warn "Webhook - \$Sts = \$dbh->do(\"update companies set comsubdue=date_add(comsubdue,interval 1 month) where comsubref='$bill->{source_id}'\")\n";
		}
        }
}
print<<EOD;
Content-Type: text/plain
Status: 200 OK


EOD

exit;
