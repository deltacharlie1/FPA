#!/usr/bin/perl

use JSON;

$Json_text = '{"redirect_flows":{"id":"RE0000CTS1AT5DJY29WNT57BBWWHQVA2","description":"FreePlus Standard","session_token":"SESS_wSs0uGYMISxzqOBq","scheme":null,"success_redirect_url":"https://example.com/pay/confirm","created_at":"2017-03-26T18:03:26.226Z","links":{"creditor":"CR00004M4FD1KK"},"redirect_url":"https://pay-sandbox.gocardless.com/flow/RE0000CTS1AT5DJY29WNT57BBWWHQVA2"}}';

$ptext = from_json($Json_text);

print $ptext->{"redirect_flows"}->{"description"}."\n";

