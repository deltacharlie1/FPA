#!/usr/bin/perl

($Key,$Flow) = split(/=/,$ENV{QUERY_STRING});

use CGI;
use JSON;
use LWP::UserAgent;
use DBI;

my $Authorization = 'Bearer sandbox_IGUCdnZP_2i58W518rZnAmQmGwiBwrGAqGQRnhSU';

$dbh = DBI->connect("DBI:mysql:fpa");
$Gcls = $dbh->prepare("select acct_id from gcls where gclflow='$Flow'");
$Gcls->execute();
@Gcl = $Gcls->fetchrow;
$Gcls->finish;

###  Complete the New Customer process

$Text = sprintf<<EOD;
{
  "data": {
    "session_token": "$Gcl[0]"
  }
}
EOD
$Text_length = length($Text);

my $ua1 = LWP::UserAgent->new;
my $req1 = HTTP::Request->new(POST => "https://api-sandbox.gocardless.com/redirect_flows/$Flow/actions/complete");

$req1->header('Content-Type' => 'application/json');
$req1->header('Content-Length' => $Text_length);
$req1->header('Accept' => 'application/json');
$req1->header('Authorization' => $Authorization);
$req1->header('GoCardless-Version' => '2015-07-06');
$req1->content($Text);

my $res1 = $ua1->request($req1);

$Res1_content = from_json($res1->content);

###  ... and get the Customer ID and Mandate ID

$Cusid = $Res1_content->{"redirect_flows"}->{"links"}->{"customer"};
$Manid = $Res1_content->{"redirect_flows"}->{"links"}->{"mandate"};

###  Set up a subscrittion starting one month from now

my $Start_date = `date +%F --date='next month - 1 day'`;
chomp($Start_date);

#    "start_date":  "$Start_date",
$Subtext = sprintf<<EOD;
{
  "subscriptions": {
    "amount": "600",
    "currency": "GBP",
    "name": "FreePlus Standard Subscription",
    "interval_unit": "monthly",
    "links": {
      "mandate": "$Manid"
    }
  }
}
EOD
$Subtext_length = length($Subtext);
my $ua2 = LWP::UserAgent->new;
my $req2 = HTTP::Request->new(POST => "https://api-sandbox.gocardless.com/subscriptions");

$req2->header('Content-Type' => 'application/json');
$req2->header('Content-Length' => $Subtext_length);
$req2->header('Accept' => 'application/json');
$req2->header('Authorization' => $Authorization);
$req2->header('GoCardless-Version' => '2015-07-06');
$req2->content($Subtext);

my $res2 = $ua2->request($req2);

$Res2_content = from_json($res2->content);
$Subid = $Res2_content->{"subscriptions"}->{"id"};
$Start = $Res2_content->{"subscriptions"}->{"start_date"};

###  Set up an initial payment for the first month for as soon as possible

###  ... and save everything

$Status = $dbh->do("update gcls set gclcusid='$Cusid',gclmanid='$Manid',gclsubid='$Subid',gclpayid='$Payid',gclsubdate='$Start',gclpaydate='$Paydate' where gclflow='$Flow'");
$dbh->disconnect;

print<<EOD;
Content-Type: text/plain
Status: 200 OK

Customer ID = $Cusid
Mandate ID = $Manid
Subscription ID = $Subid
Subscription Start Date = $Start

First Payment ID = $Payid
First Payment Date = $Paydate
Pay Status = $Paystatus
EOD
exit;

$Paytext = sprintf<<EOD;
{
  "payments": {
    "amount": 600,
    "currency": "GBP",
    "description":  "FreePlus Standard Initial Payment",
    "links": {
      "mandate": "$Manid"
    }
  }
}
EOD
$Paytext_length = length($Paytext);
my $ua3 = LWP::UserAgent->new;
my $req3 = HTTP::Request->new(POST => "https://api-sandbox.gocardless.com/payments");

$req3->header('Content-Type' => 'application/json');
$req3->header('Content-Length' => $Paytext_length);
$req3->header('Accept' => 'application/json');
$req3->header('Authorization' => $Authorization);
$req3->header('GoCardless-Version' => '2015-07-06');
$req3->content($Paytext);

my $res3 = $ua3->request($req3);

$Res3_content = from_json($res3->content);
$Payid = $Res3_content->{"payments"}->{"id"};
$Paydate = $Res3_content->{"payments"}->{"charge_date"};
$Paystatus = $res3->status_line();;
