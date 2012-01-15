#!/usr/bin/perl

#  Script to receive a subscription
#  response comes in as xml

($FORM{MERCHANTREF},$Old_subtype) = split(/\?/,$ENV{QUERY_STRING});		#  This is Merchantref

use LWP::UserAgent;
use Digest;
use DBI;
$dbh = DBI->connect("DBI:mysql:fpa");

$Termid = '2645001';
$Secret = 'CorunnaSecret';

$Membership[0] = 'FreePlus Startup (FREE)';
$Membership[1] = 'FreePlus Standard (&pound;5.00pm)';
$Membership[2] = 'FreePlus Premium (&pound;10.00pm)';

#  Get the company details

$Companies = $dbh->prepare("select comsublevel,comsubtype,commerchantref,comcardref,comsubref,comname from companies where commerchantref='$FORM{MERCHANTREF}'");
$Companies->execute;
$Company = $Companies->fetchrow_hashref;
$Companies->finish;
$Level = $Company->{comsublevel};

#  Get the date

$Dte = `date +%d-%m-%Y:%H:%M:%S:000`;
chomp($Dte);

$Startdate = $Dte;
$Startdate =~ s/:.*//;

#  comsublevel = del - Cancel subscription & card
#		 00  - New subscription
#		 >0  - Change existing subscription to new comsubtype  (delete old add new)


if ($Company->{comsublevel} =~ /Del/i) {		#  Delete existing subscription

	$Hash = Digest->new("MD5");
	$Hash->add($Termid.$Company->{comsubref}.$Dte.$Secret);
	$Hash_text = $Hash->hexdigest;

#  Construct the xml to be posted

#  Note <MERCHANTREF> here is a reference for the actual subscription

	$Content = sprintf<<EOD;
<?xml version="1.0" encoding="UTF-8"?>
<DELETESUBSCRIPTION>
  <MERCHANTREF>$Company->{comsubref}</MERCHANTREF>
  <TERMINALID>$Termid</TERMINALID>
  <DATETIME>$Dte</DATETIME>
  <HASH>$Hash_text</HASH>
</DELETESUBSCRIPTION>
EOD

#  Now send it

	my $ua = LWP::UserAgent->new;
	$ua->agent("FPA/0.1");

	my $req = HTTP::Request->new(POST => "https://testcashflows.worldnettps.com/merchant/xmlpayment");
	$req->content_type('text/xml');
	$req->content($Content);

	my $res = $ua->request($req);

	if ($res->is_success) {
		$Res_content = $res->content;

		if ($Res_content =~ /RESPONSE/i) {
			$Status .= "<li>Subscription Cancelled</li>\n";
			$Sts = $dbh->do("update companies set comsublevel='00',comsubtype='' where commerchantref='$Company->{commerchantref}'");

#  update the database
		}
		else {
			$Status .= "<li>Subscription not cancelled, please contact FreePlus Accounts Technical Support</li>\n";
		}
	}
	else {
		$Status .= "<li>Subscription not cancelled, please contact FreePlus Accounts Technical Support</li>\n";
	}

#  Delete the secure card


	$Hash = Digest->new("MD5");
	$Hash->add($Termid.$Company->{commerchantref}.$Dte.$Company->{comcardref}.$Secret);
	$Hash_text = $Hash->hexdigest;

#  Construct the xml to be posted

	$Content = sprintf<<EOD;
<?xml version="1.0" encoding="UTF-8"?>
<SECURECARDREMOVAL>
  <MERCHANTREF>$Company->{commerchantref}</MERCHANTREF>
  <CARDREFERENCE>$Company->{comcardref}</CARDREFERENCE>
  <TERMINALID>$Termid</TERMINALID>
  <DATETIME>$Dte</DATETIME>
  <HASH>$Hash_text</HASH>
</SECURECARDREMOVAL>
EOD

#  and send the card cancellation

	my $ua = LWP::UserAgent->new;
	$ua->agent("FPA/0.1");

	my $req = HTTP::Request->new(POST => "https://testcashflows.worldnettps.com/merchant/xmlpayment");
	$req->content_type('text/xml');
	$req->content($Content);

	my $res = $ua->request($req);
	if ($res->is_success) {

		$Res_content = $res->content;

		if ($Res_content =~ /RESPONSE/i) {

			$Status .= "<li>Card Details Deleted</li>\n";
			$Level = 0;
			$Sts = $dbh->do("update companies set comsublevel='00',comsubtype='',commerchantref='',comcardref='' where commerchantref='$Company->{commerchantref}'");

		}
		else {
			$Status .= "<li>Card Details not deleted, please contact FreePlus Accounts Technical Support</li>\n";
		}
	}
	else {
		$Status .= "<li>Card Details not deleted, please contact FreePlus Accounts Technical Support</li>\n";
	}
}
elsif ($Company->{comsublevel} =~ /00/) {	#  New subscription

	$Subref = $$.time;

	$Hash = Digest->new("MD5");
	$Hash->add($Termid.$Subref.$Company->{comsubtype}.$Company->{commerchantref}.$Dte.$Startdate.$Secret);
	$Hash_text = $Hash->hexdigest;

#  Construct the xml to be posted

#  Note <MERCHANTREF> here is a reference for the actual subscription

	$Content = sprintf<<EOD;
<?xml version="1.0" encoding="UTF-8"?>
<ADDSUBSCRIPTION>
  <MERCHANTREF>$Subref</MERCHANTREF>
  <TERMINALID>$Termid</TERMINALID>
  <STOREDSUBSCRIPTIONREF>$Company->{comsubtype}</STOREDSUBSCRIPTIONREF>
  <SECURECARDMERCHANTREF>$Company->{commerchantref}</SECURECARDMERCHANTREF>
  <DATETIME>$Dte</DATETIME>
  <STARTDATE>$Startdate</STARTDATE>
  <HASH>$Hash_text</HASH>
</ADDSUBSCRIPTION>
EOD

	my $ua = LWP::UserAgent->new;
	$ua->agent("FPA/0.1");

	my $req = HTTP::Request->new(POST => "https://testcashflows.worldnettps.com/merchant/xmlpayment");
	$req->content_type('text/xml');
	$req->content($Content);

	my $res = $ua->request($req);

	if ($res->is_success) {

		$Res_content = $res->content;

		if ($Res_content =~ /RESPONSE/i) {

			$Status .= "<li>Your subscription has been accepted, thank you</li>\n";
			$Level = $Company->{comsubtype};
			$Level =~ s/.+(\d)$/$1/;

			$Sts = $dbh->do("update companies set comsublevel='$Level',comsubref='$Subref',comsubs='2020-12-31' where commerchantref='$Company->{commerchantref}'");
		}
		else {
			$Status .= "<li>Your subscription has not been accepted for some reason, please contact FreePlus Accounts Technical Support</li>\n";
		}
	}
	else {
		$Status .= "<li>Your subscription has not been accepted for some reason, please contact FreePlus Accounts Technical Support</li>\n";
	}
}
elsif ($Company->{comsublevel} > 0) {		#  Updating subscription

#  First delete the existing subscription, then add the new one

#  Delete

	$Hash = Digest->new("MD5");
	$Hash->add($Termid.$Company->{comsubref}.$Dte.$Secret);
	$Hash_text = $Hash->hexdigest;

#  Construct the xml to be posted

	$Content = sprintf<<EOD;
<?xml version="1.0" encoding="UTF-8"?>
<DELETESUBSCRIPTION>
  <MERCHANTREF>$Company->{comsubref}</MERCHANTREF>
  <TERMINALID>$Termid</TERMINALID>
  <DATETIME>$Dte</DATETIME>
  <HASH>$Hash_text</HASH>
</DELETESUBSCRIPTION>
EOD

#  Now send it

	my $ua = LWP::UserAgent->new;
	$ua->agent("FPA/0.1");

	my $req = HTTP::Request->new(POST => "https://testcashflows.worldnettps.com/merchant/xmlpayment");
	$req->content_type('text/xml');
	$req->content($Content);

	my $res = $ua->request($req);

	if ($res->is_success) {

		$Res_content = $res->content;

		if ($Res_content =~ /RESPONSE/i) {

#  Now add the new one

			$Status .= "<li>Old Subscription Cancelled</li>\n";

			$Subref = $$.time;

			$Hash = Digest->new("MD5");
			$Hash->add($Termid.$Subref.$Company->{comsubtype}.$Company->{commerchantref}.$Dte.$Startdate.$Secret);
			$Hash_text = $Hash->hexdigest;

#  Construct the xml to be posted

#  Note <MERCHANTREF> here is a reference for the actual subscription

			$Content = sprintf<<EOD;
<?xml version="1.0" encoding="UTF-8"?>
<ADDSUBSCRIPTION>
  <MERCHANTREF>$Subref</MERCHANTREF>
  <TERMINALID>$Termid</TERMINALID>
  <STOREDSUBSCRIPTIONREF>$Company->{comsubtype}</STOREDSUBSCRIPTIONREF>
  <SECURECARDMERCHANTREF>$Company->{commerchantref}</SECURECARDMERCHANTREF>
  <DATETIME>$Dte</DATETIME>
  <STARTDATE>$Startdate</STARTDATE>
  <HASH>$Hash_text</HASH>
</ADDSUBSCRIPTION>
EOD

#  and send the card cancellation

			my $ua = LWP::UserAgent->new;
			$ua->agent("FPA/0.1");

			my $req = HTTP::Request->new(POST => "https://testcashflows.worldnettps.com/merchant/xmlpayment");
			$req->content_type('text/xml');
			$req->content($Content);

			my $res = $ua->request($req);

			if ($res->is_success) {

				$Res_content = $res->content;
	
				if ($Res_content =~ /RESPONSE/i) {
					$Status .= "<li>New Subscription Added</li>\n";

#  update the database
					$Level = $Company->{comsubtype};
					$Level =~ s/.+(\d)$/$1/;

					$Sts = $dbh->do("update companies set comsublevel='$Level',comsubref='$Subref',comsubs='2020-12-31' where commerchantref='$Company->{commerchantref}'");


				}
				else {
					$Status .= "<li>New subsription not added, please contact FreePlus Accounts Technical Support</li>\n";
				}
			}
			else {
				$Status .= "<li>New subsription not added, please contact FreePlus Accounts Technical Support</li>\n";
			}
		}
		else {
			$Status .= "<li>Old Subscription not cancelled, please contact FreePlus Accounts Technical Support</li>\n";
		}
	}
	else {
		$Status .= "<li>Old Subscription not cancelled, please contact FreePlus Accounts Technical Support</li>\n";
	}
}
use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib']
});

$Vars = { company => $Company,
	  membership => $Membership[$Level],
          status => $Status
};

print "Content-Type: text/html\n\n";
$tt->process('sub_subscribe.tt',$Vars);
$dbh->disconnect;
exit;

