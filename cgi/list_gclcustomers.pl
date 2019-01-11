#!/usr/bin/perl

#  This script lists active GCL customers with one or more active subscriptions

my $Authorization = 'Bearer live_m2elMSXaTSObKqlTGBGTmy3aMivybF94fROuZCej';

use LWP;
use JSON;
$json = JSON->new->allow_nonref;

my $ua = LWP::UserAgent->new;
my $req = HTTP::Request->new(GET => "https://api.gocardless.com/customers");

$req->header('Content-Type' => 'application/json');
#	$req->header('Content-Length' => $Paytext_length);
$req->header('Accept' => 'application/json');
$req->header('Authorization' => $Authorization);
$req->header('GoCardless-Version' => '2015-07-06');
#	$req->content($Paytext);

my $res = $ua->request($req);
$mandates_scalar = $json->decode( $res->content );
$Mandates = $mandates_scalar->{customers};
$Count = 0;
for $Mandate ( @{$Mandates} ) {
#	if ($Mandate->{status} =~ /active/) {
		$Count++;
		print "$Mandate->{status}\t$Mandate->{id}\t$Mandate->{email}\t$Mandate->{created_at}\t$Mandate->{given_name} $Mandate->{family_name}\n";
#	}
}
print "\n\n$Count records updated\n";
exit;

