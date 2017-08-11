#!/usr/bin/perl

use JSON;

$Text = '{"mandates":{"id":"MD00020PW7YHVT","created_at":"2017-07-31T15:20:18.412Z","reference":"CORUNNASYSTE-VH6RV","status":"cancelled","scheme":"bacs","next_possible_charge_date":null,"payments_require_approval":false,"metadata":{},"links":{"customer_bank_account":"BA0001Z5AQC51E","creditor":"CR00004M4FD1KK","customer":"CU000258N6DKX1"}}}';

$dd = from_json($Text);

print $dd->{mandates}->{status}."\n";
exit;

