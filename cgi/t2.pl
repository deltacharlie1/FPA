#!/usr/bin/perl

#  Script to access the gocardless api

$Function = $ARGV[0];

unless ($Function =~ /users|subscriptions|bills/) {
	print "\n\n\tUsage: ./t2.pl <users|subscriptions|bills>\n\n\n";
	exit;
}

use JSON;
use LWP::UserAgent;

my $ua = LWP::UserAgent->new;
my $req = HTTP::Request->new(GET => "https://sandbox.gocardless.com/api/v1/merchants/0205HPKCHY/$Function");
# my $req = HTTP::Request->new(PUT => "https://sandbox.gocardless.com/api/v1/subscriptions/020YE8MGWA/cancel");
$req->header('Content-Type' => 'text/plain');
$req->header('Accept' => 'application/json');
$req->header('Authorization' => 'bearer 8bztbuIDFtSTNPZTgQ1ELVa/XCRQqc04tldN/8L4PpvfT4SK4GS93vKw4hkj6tCM');
# $req->header('Content-Length' => '0');

my $res = $ua->request($req);

$Data = decode_json($res->content);

if ($Function =~ /users/) {
	foreach $json (@$Data) {

		$req->uri("https://sandbox.gocardless.com/api/v1/users/$json->{id}");
		$res = $ua->request($req);
		$User = decode_json($res->content);
		while (($Key,$Value) = each %$User) {
			print "$Key = $Value\n";
		}
		print "\n";
		
	}
}
else {
	foreach $json (@$Data) {
		while (($Key,$Value) = each %$json) {
			print "$Key = $Value\n";
		}
		print "\n";
		
	}
	
}

# print $res->content."\n";
