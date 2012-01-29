#!/usr/bin/perl

#  Script to receive a subscription
#  response comes in as xml
$ACCESS_LEVEL = 1;

#  script to display the registration screen tuned to reregistering

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

@Cookie = split(/\;/,$ENV{HTTP_COOKIE});
foreach (@Cookie) {
        ($Name,$Value) = split(/\=/,$_);
        $Name =~ s/^ //g;
        $Value =~ tr/\"//d;
        $Cookie{$Name} = $Value;
}

($FORM{MERCHANTREF},$Old_subtype) = split(/\?/,$ENV{QUERY_STRING});		#  This is Merchantref

use LWP::UserAgent;
use Digest;
use DBI;
$dbh = DBI->connect("DBI:mysql:fpa");
unless ($COOKIE->{NO_ADS}) {
        require "/usr/local/git/fpa/cgi/display_adverts.ph";
        &display_adverts();
}

open(XML,'</usr/local/git/fpa/other/cashflows') || warn "Could not open cashflos file\n";
@Xmlstr = <XML>;
close(XML);

($Termid,$Secret,$URL) = @Xmlstr;
chomp($Termid);
chomp($Secret);
chomp($URL);

open(LOG,">>/var/log/cashflows.log");

#$Termid = '2645001';
#$Secret = 'CorunnaSecret';
#$Termid = '2706001';
#$Secret = 'F1sherfolK';

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

$Companies = $dbh->prepare("select id,reg_id,comsublevel,comsubtype,commerchantref,comcardref,comsubref,comname,date_format(comsubdue,'%d-%b-%y') as subdue from companies where commerchantref='$FORM{MERCHANTREF}'");
$Companies->execute;
$Company = $Companies->fetchrow_hashref;
$Companies->finish;
$Level = $Company->{comsublevel};

#  Get the date

$Dte = `date +%d-%m-%Y:%H:%M:%S:000`;
chomp($Dte);

$Startdate = $Dte;
$Startdate =~ s/:.*//;


if ($Company->{comsubtype} =~ /cancel/i) {		#  Delete existing subscription

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

	my $req = HTTP::Request->new(POST => "https://$URL.worldnettps.com/merchant/xmlpayment");
	$req->content_type('text/xml');
	$req->content($Content);

	my $res = $ua->request($req);

	$Res_content = $res->content;

	print LOG $Company->{reg_id}."+".$Company->{id}." - Remove Card - ".$Res_content."\n";

	$Level = 0;
	$Sts = $dbh->do("update companies set comsublevel='00',comsubtype='',comsubref='',commerchantref='',comcardref='',comsubdue='2010-01-01',compt_logo='2010-01-01',comuplds=0,comno_ads='2010-01-01' where commerchantref='$Company->{commerchantref}'");
	$Sts = $dbh->do("update registrations set regmembership='1' where reg_id=$Company->{reg_id}");
	$Status .= "<p>Your subscription has been cancelled.</p><p>We are sorry to see you go but have reverted you to FreePlus Startup which is completely free to use.</p>\n";
	$Company->{comsubtype} = 'Del';		# so as to display correct new subscription
	&update_cookiefile();
}
elsif ($Company->{comsublevel} =~ /00/) {	#  New subscription

	$Status .= "<p>Thank you for subscribing to FreePlus Accounts.</p><p>Your subscription choice of <b>$Subtype{$Company->{comsubtype}}</b> has now been set up.</p><p>Your 30 day free period begins immediately and you may cancel at any time without incurring any cost.&nbsp;&nbsp;If, after that time, you wish to ocntinue using the additional features you will need to enter your credit/debit card details by going to 'My Account' and clicking on the 'Update Card Details' tab.&nbsp;&nbsp;To help you, we will send you a reminder email a few days before the free period is due to end.</p>\n";
	$Level = $Company->{comsubtype};
	$Level =~ s/.+(\d)$/$1/;

	$Sts = $dbh->do("update companies set comsublevel='$Level',comsubdue=date_add(str_to_date('$Startdate','%d-%m-%Y'),interval 30 day),comadd_user='1' where commerchantref='$Company->{commerchantref}'");
	$Sts = $dbh->do("update registrations set regmembership='$Membership[$Level]' where reg_id=$Company->{reg_id}");
	&update_cookiefile();
}
elsif ($Company->{comsublevel} > 0) {		#  Updating subscription

	$Status .= "<li>Your new subscription, <b>$Subtype{$Company->{comsubtype}}</b>, has been set up</li>\n";
	$Status .= "<li>The new payments will start on $Company->{subdue} and monthly thereafter</li></ul>\n";

#  update the database
	$Level = $Company->{comsubtype};
	$Level =~ s/.+(\d)$/$1/;

	$Sts = $dbh->do("update companies set comsublevel='$Level' where commerchantref='$Company->{commerchantref}'");
	$Sts = $dbh->do("update registrations set regmembership='$Membership[$Level]' where reg_id=$Company->{reg_id}");
	&update_cookiefile();
}

close(LOG);

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
	WRAPPER => 'header.tt'
});

$Vars = { company => $Company,
	  title => 'Subscriptions',
	  cookie => $COOKIE,
	  membership => $Subtype{$Company->{comsubtype}},
          status => $Status
};

print "Content-Type: text/html\n\n";
$tt->process('sub_subscribe.tt',$Vars);
$dbh->disconnect;
exit;

sub update_cookiefile {
open(FILE,"</projects/tmp/$Cookie{'fpa-cookie'}");
while (<FILE>) {
        chomp($_);
        ($Key,$Value) = split(/\t/,$_);
        $DATA{$Key} = $Value;
}
close(FILE);

$DATA{PLAN} = $Membership[$Level];
$DATA{ACCESS} = $Membership[$Level];

unlink("/projects/tmp/$Cookie{'fpa-cookie'}");

open(FILE,">/projects/tmp/$Cookie{'fpa-cookie'}");
while(($Key,$Value) = each %DATA) {
        print FILE "$Key\t$Value\n";
}
close(FILE);
}
