#!/usr/bin/perl

$Facility = `cat /usr/local/git/fpa/other/.gocardless`;
chomp($Facility);
if ($Facility =~ /live/i) {
	$Client_id = 'L4s4jrtE8p0B9X2LOTxR_aE4V_rBNjyZEkkhBFlVV9Lhv2MYIISOuFGDhL6z2baD';		#  App identifief
	$App_key = 'eTzWcFjDjsPpd_GhwWBH4ovB_MyYQJDr5snpHOeEohF6uamIVWMnLUE2yJ_Cfl_A';			#  App secret
	$Authorization = 'bearer 7koL7/6N7eexnQeYyZz24/r7pevUuO1tA6ZH+A0SjX0pDV42z/YXodG5KuIUdKfm';	#  Merchant access token
	$Merchant_id = '0265HC17QC';									#  Merchant id
	$Dom = '';
}
else {
	$Client_id = 'sRjngasG1PNtIT06u33yZMu7ftXDaDe4ARaXFY2U8FYaDc_bGLmV7UAIme9KZczj';		#  App identifier
	$App_key = '5hs3wSzzMuUarQFy_5Z2frezxymWhZK9dLEtkpDUBHBnjE7DjqJH1Js94MmR_6Fe';			#  App secret
	$Authorization = 'bearer 8bztbuIDFtSTNPZTgQ1ELVa/XCRQqc04tldN/8L4PpvfT4SK4GS93vKw4hkj6tCM';	#  Merchant access token
	$Merchant_id = '0205HPKCHY';									#  Merchant Id
	$Dom = 'sandbox.';
}

use LWP::UserAgent;
use LWP::Protocol::https;
use JSON;
use DBI;

my $dbh = DBI->connect("DBI:mysql:fpa");
	
my $ua = LWP::UserAgent->new;
#my $req = HTTP::Request->new(GET => "https://gocardless.com/api/v1/merchants/$Merchant_id/bills?paid=true&after=2016-05-06T12:00:00Z");
#my $req = HTTP::Request->new(GET => "https://gocardless.com/api/v1/merchants/$Merchant_id/subscriptions?user_id=CU0002KKZMDV0T");
#my $req = HTTP::Request->new(GET => "https://gocardless.com/api/v1/merchants/$Merchant_id/subscriptions?status=active");
my $req = HTTP::Request->new(GET => "https://gocardless.com/api/v1/merchants/$Merchant_id/users?status=active");
$req->header('Content-Type' => 'text/plain');
$req->header('Content-Length' => '0');
$req->header('Accept' => 'application/json');
$req->header('Authorization' => $Authorization);

my $res = $ua->request($req);

$Res_content = $res->content;
$json = JSON->new->allow_nonref;
$users_scalar = $json->decode($Res_content);
$Count = 0;
#print $Res_content;

for $User (@{$users_scalar}) {
	$Count++;

	if ($User->{email} =~ /fowlersite/) {
		$User->{email} = 'carol.fowler@hotmail.com';
	}

	$Sts = $dbh->do("update companies join registrations on companies.reg_id=registrations.reg_id set companies.comcusref='$User->{id}' where registrations.regemail='$User->{email}'");

	if ($Sts < 1) {
		print "No update - $User->{id}\t: $User->{email}\n";
	}
	else {
		print "Updated   - $User->{id}\t: $User->{email}\n";
	}
}
$dbh->disconnect();

print "\n\nNumber of customers found = $Count\n";
exit;
