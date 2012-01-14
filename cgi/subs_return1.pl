#!/usr/bin/perl

#  Script to receive a secure card response and, if ok, create a subscription
#  response comes in as a get string

$Buffer = $ENV{QUERY_STRING};

@pairs = split(/&/,$Buffer);

foreach $pair (@pairs) {

        ($Name, $Value) = split(/=/, $pair);

        $Value =~ tr/+/ /;
        $Value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C",hex($1))/eg;
        $Value =~ tr/\\//d;             #  Remove all back slashes
        $Value =~ s/(\'|\")/\\$1/g;
        $FORM{$Name} = $Value;
}

use DBI;
$dbh = DBI->connect("DBI:mysql:fpa");

if ($FORM{RESPONSECODE} =~ /A/i) {

#  Get the company details

	$Companies = $dbh->prepare("select comsublevel,comsubtype,commerchantref,comcardref from companies where commerchantref='$FORM{MERCHANTREF}'");
	$Companies->execute;
	$Company = $Companies->fetchrow_hashref;
	$Companies->finish;

	if ($Company->{comsublevel}=~ /00/) {		#  New subscription so send xml

#  Get the date

		$Dte = `date +%d-%m-%Y:%H:%M:%S:000`;
		chomp($Dte);

		$Startdate = $Dte;
		$Startdate =~ s/:.*//;

#  Calculate Hash term,merchref,securecardref,date,startdate,secret

		use Digest;
		$Hash = Digest->new("MD5");
		$Hash->add('2645001'.$Company->{comsubtype}.$Company->{commerchantref}.$Company->{comsubtype}.$Company->{commerchantref}.$Dte.$Startdate.'CorunnaSecret');
		$Hash_text = $Hash->hexdigest;

#  Construct the xml to be posted

#  Note <MERCHANTREF> here is a reference for the actual subscription

		$Content = sprintf<<EOD;
<?xml version="1.0" encoding="UTF-8"?>
<ADDSUBSCRIPTION>
  <MERCHANTREF>$Company->{comsubtype}$Company->{commerchantref}</MERCHANTREF>
  <TERMINALID>2645001</TERMINALID>
  <STOREDSUBSCRIPTIONREF>$Company->{comsubtype}</STOREDSUBSCRIPTIONREF>
  <SECURECARDMERCHANTREF>$Company->{commerchantref}</SECURECARDMERCHANTREF>
  <DATETIME>$Dte</DATETIME>
  <STARTDATE>$Startdate</STARTDATE>
  <HASH>$Hash_text</HASH>
</ADDSUBSCRIPTION>
EOD

warn "$Content\n\n";

#  Now send it

		use LWP::UserAgent;
		my $ua = LWP::UserAgent->new;
		$ua->agent("FPA/0.1");

		my $req = HTTP::Request->new(POST => "https://testcashflows.worldnettps.com/merchant/xmlpayment");
		$req->content_type('text/xml');
		$req->content($Content);

		my $res = $ua->request($req);

		if ($res->is_success) {

#  update the database

			$Res_content = $res->content;
warn "$Res_content\n\n";

			print "Content-Type: text/plain\n\n";
			print $Res_content."\n";
		}
	}
}
print "Content-Type: text/plain\n\n";
print "Ending\n";
$dbh->disconnect;

exit;

