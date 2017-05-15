#!/usr/bin/perl

use CGI;
use JSON;
use LWP::UserAgent;
use DBI;

my $dbh = DBI->connect("DBI:mysql:fpa");

my $Authorization = 'Bearer sandbox_IGUCdnZP_2i58W518rZnAmQmGwiBwrGAqGQRnhSU';
my $Acct_id = "1444+5678";

$Text = sprintf<<EOD;
{
  "redirect_flows": {
    "description": "FreePlus Accounts",
    "session_token": "$Acct_id",
    "success_redirect_url": "https://www.freeplusaccounts.co.uk/cgi-bin/fpa/test_cus_create2.pl",
    "prefilled_customer": {
      "given_name": "Successful",
      "family_name": "Successful",
      "email": "info\@corunna.com"
    }
  }
}
EOD
$Text_length = length($Text);

my $ua = LWP::UserAgent->new;
my $req = HTTP::Request->new(POST => "https://api-sandbox.gocardless.com/redirect_flows");

$req->header('Content-Type' => 'application/json');
$req->header('Content-Length' => $Text_length);
$req->header('Accept' => 'application/json');
$req->header('Authorization' => $Authorization);
$req->header('GoCardless-Version' => '2015-07-06');
$req->content($Text);

my $res = $ua->request($req);

$Res_content = from_json($res->content);
$Url = $Res_content->{"redirect_flows"}->{"redirect_url"};
$Flow = $Res_content->{"redirect_flows"}->{"id"};

$Status = $dbh->do("delete from gcls where acct_id='$Acct_id'");
$Status = $dbh->do("insert into gcls (acct_id,gclflow) values ('$Acct_id','$Flow')");
$dbh->disconnect;


print<<EOD;
Content-Type: text/html
Status: 302
Location: $Url

EOD
exit;
