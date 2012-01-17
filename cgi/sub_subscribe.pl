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

$Membership[0] = '1';
$Membership[1] = '3';
$Membership[2] = '4';
$Membership[3] = '5';
$Membership[5] = '6';
$Membership[6] = '8';

$Subtype{Del} = 'FreePlus Startup (FREE)';
$Subtype{fpa1} = 'FreePlus Bookkeeper Basic (&pound;5.00pm)';
$Subtype{fpa2} = 'FreePlus Standard (&pound;5.00pm)';
$Subtype{fpa3} = 'FreePlus Bookkeeper Standard (&pound;10.00pm)';
$Subtype{fpa5} = 'FreePlus Premium (&pound;10.00pm)';
$Subtype{fpa6} = 'FreePlus Bookkeeper Premium (&pound;20.00pm)';

#  Get the company details

$Companies = $dbh->prepare("select id,reg_id,comsublevel,comsubtype,commerchantref,comcardref,comsubref,comname from companies where commerchantref='$FORM{MERCHANTREF}'");
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
#		 00  - New subscription - create new subscription and initial addpayment
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
			$Status .= "<li>Your subscription is cancelled.  New subscription:- <b>$Subtype{$Company->{comsublevel}}</b></li>\n";
			$Company->{comsubtype} = $Company->{comsublevel};	# so as to display correct new subscription
			$Sts = $dbh->do("update companies set comsublevel='00',comsubtype='',comsubref='',comsubdue='2010-01-01' where commerchantref='$Company->{commerchantref}'");
			$Sts = $dbh->do("update registrations set regmembership='1' where reg_id=$Company->{reg_id}");

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

			$Status .= "<li>Your card details  have been removed</li>\n";
			$Level = 0;
			$Sts = $dbh->do("update companies set comsublevel='00',comsubtype='',comsubref='',commerchantref='',comcardref='' where commerchantref='$Company->{commerchantref}'");
			$Sts = $dbh->do("update registrations set regmembership='1' where reg_id=$Company->{reg_id}");

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
#  As this is a new subscription we subscription due date to start date (today).  It will then be picked up[ by the daily payments run

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

			$Status .= "<li>Thank you, you are now subscribed to:- <b>$Subtype{$Company->{comsubtype}}</b></li>\n";
			$Level = $Company->{comsubtype};
			$Level =~ s/.+(\d)$/$1/;

#  Allow logo & statements?

			if ($Company->{comsubtype} =~ /fpa1/i) {
				$Logo = "'2010-01-01'";
				$Stmts = "'2010-01-01'";
			}
			else {
				$Logo = "str_to_date('$Startdate','%d-%m-%Y')";
				$Stmts = "str_to_date('$Startdate','%d-%m-%Y')";
			}
#  Do we add a user login?

			if ($Company->{comsubtype} =~ /fpa2|fpa5/i) {
				$Add_user = "1";
			}
			else {
				$Add_user = "0";
			}

#  Do we add no ads, uploads etc ?

			if ($Company->{comsubtype} =~ /fpa5|fpa6/i) {
				$No_ads = "str_to_date('$Startdate','%d-%m-%Y')";
				$Uplds = 524288;
				$Keep_recs = "str_to_date('$Startdate','%d-%m-%Y')";
			}
			else {
				$No_ads = "'2010-01-01'";
				$Uplds = 0;
				$Keep_recs = "'2010-01-01'";
			}

			$Sts = $dbh->do("update companies set comsublevel='$Level',comsubref='$Subref',comsubdue=str_to_date('$Startdate','%d-%m-%Y'),comno_ads=$No_ads,comuplds=$Uplds,comkeep_recs=$Keep_recs,compt_logo=$Logo,comstmts=$Stmts,comadd_user='$Add_user' where commerchantref='$Company->{commerchantref}'");
			$Sts = $dbh->do("update registrations set regmembership='$Membership[$Level]' where reg_id=$Company->{reg_id}");
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
					$Status .= "<li>New subscription is:- <b>$Subtype{$Company->{comsubtype}}</b></li>\n";

#  update the database
					$Level = $Company->{comsubtype};
					$Level =~ s/.+(\d)$/$1/;

					$Sts = $dbh->do("update companies set comsublevel='$Level',comsubref='$Subref' where commerchantref='$Company->{commerchantref}'");
					$Sts = $dbh->do("update registrations set regmembership='$Membership[$Level]' where reg_id=$Company->{reg_id}");


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
	  membership => $Subtype{$Company->{comsubtype}},
          status => $Status
};

print "Content-Type: text/html\n\n";
$tt->process('sub_subscribe.tt',$Vars);
$dbh->disconnect;
exit;

