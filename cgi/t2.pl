#!/usr/bin/perl

#  Script to access the gocardless api

use LWP::UserAgent;
use Digest;

my $ua = LWP::UserAgent->new;
my $req = HTTP::Request->new(GET => "https://sandbox.gocardless.com/api/v1/merchants/0205HPKCHY/subscriptions");
# my $req = HTTP::Request->new(PUT => "https://sandbox.gocardless.com/api/v1/subscriptions/020YE8MGWA/cancel");
# $req->content_type('text/plain');
$req->header('Content-Type' => 'text/plain');
# $req->header('Content-Length' => '0');
$req->header('Accept' => 'application/xml');
$req->header('Authorization' => 'bearer 8bztbuIDFtSTNPZTgQ1ELVa/XCRQqc04tldN/8L4PpvfT4SK4GS93vKw4hkj6tCM');
# $req->header('Content-Length' => '0');

my $res = $ua->request($req);

#$Res_content = $res->content;

#print $Res_content."\n";

print $res->as_string;

