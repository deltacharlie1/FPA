#!/usr/bin/perl
#

use JSON;

$Txt = sprintf<<EOD;
{"events":[{"id":"EV000N2ZKPKBE1","created_at":"2017-05-17T16:37:10.011Z","resource_type":"mandates","action":"cancelled","links":{"mandate":"MD0001QXYTYXDH"},"details":{"origin":"api","cause":"mandate_cancelled","description":"The mandate was cancelled at your request."},"metadata":{}},{"id":"EV000N2ZKQQ5C7","created_at":"2017-05-17T16:37:10.035Z","resource_type":"payments","action":"cancelled","links":{"parent_event":"EV000N2ZKPKBE1","payment":"PM0004ER4STS5H"},"details":{"origin":"api","cause":"mandate_cancelled","description":"The mandate for this payment was cancelled at your request."},"metadata":{}},{"id":"EV000N2ZKR2RYH","created_at":"2017-05-17T16:37:10.065Z","resource_type":"subscriptions","action":"cancelled","links":{"subscription":"SB00005XNFJQ0X"},"details":{"origin":"api","cause":"mandate_cancelled","description":"The subscription was cancelled because its mandate was cancelled at your request."},"metadata":{}}]}
EOD

$json = JSON->new->allow_nonref;
 
# $json_text   = $json->encode( $perl_scalar );

$perl = decode_json($Txt);

for $value (values %$perl) {
	@Events = @$value;
	for $Event (@Events) {
		print "Val = $Event->{'links'}\n";
	}
}
print "\n";
