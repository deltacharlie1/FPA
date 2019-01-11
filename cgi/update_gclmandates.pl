#!/usr/bin/perl

#  Script to list mandates

my $Authorization = 'Bearer live_m2elMSXaTSObKqlTGBGTmy3aMivybF94fROuZCej';

use DBI;
$dbh = DBI->connect("DBI:mysql:fpa");
use LWP;
use JSON;
$json = JSON->new->allow_nonref;

my $ua = LWP::UserAgent->new;
my $req = HTTP::Request->new(GET => "https://api.gocardless.com/mandates?status=active");

$req->header('Content-Type' => 'application/json');
#	$req->header('Content-Length' => $Paytext_length);
$req->header('Accept' => 'application/json');
$req->header('Authorization' => $Authorization);
$req->header('GoCardless-Version' => '2015-07-06');
#	$req->content($Paytext);

my $res = $ua->request($req);
$mandates_scalar = $json->decode( $res->content );
$Mandates = $mandates_scalar->{mandates};
$Count = 0;
for $Mandate ( @{$Mandates} ) {
	$Sts = $dbh->do("update companies set commandateref='$Mandate->{id}' where comcusref='$Mandate->{links}->{customer}'");
	if ($Sts > 0) {
		$Count++;
		print "Found - $Mandate->{id}\t$Mandate->{created_at}\t$Mandate->{links}->{customer}\n";
	}
	else {
		print "Not Found - $Mandate->{id}\t$Mandate->{created_at}\t$Mandate->{links}->{customer}\n";
	}
}
$dbh->disconnect();
print "\n\n$Count records updated\n";
exit;

