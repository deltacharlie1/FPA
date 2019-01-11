#!/usr/bin/perl

#  This is the starting point for a new subscriber.  This program initiates the subscription process with GoCardless
#  and gets the unique 'Redirect Flows' ID so as to use the GoCardless setup facility.
#
#  Once the Redirect flows ID has been received it then hands over to GCL who complete the process and then
#  hand back to newsubs2.pl
#
#  0  -  FreePlus Free (£0pm)
#  1  -  Freeplus Basic (Bookeeper) (£5)
#  2  -  Freeplus Standard (£5)
#  3  -  Freeplus Standard Bookkeeper (£10)
#  4  -  Freeplus Premium  (£10)
#  5  -  Freeplus Premium Bookkeeper  (£20)

#  Set up strings to send to GCL

use CGI;
use JSON;
use LWP::UserAgent;
use DBI;
use Checkid;

@Sub_name=("FreePlus Free Edition","Bookkeeper Basic","FreePlus Standard","Bookkeeper Standard","FreePlus Premium","Bookkeeper Premium");

@Sub_amt = ("000","6.00","6.00","12.00","12.00","24.00");

my $dbh = DBI->connect("DBI:mysql:fpa");

my $Authorization = 'Bearer sandbox_IGUCdnZP_2i58W518rZnAmQmGwiBwrGAqGQRnhSU';
my $Live_Auth = 'Bearer live_m2elMSXaTSObKqlTGBGTmy3aMivybF94fROuZCej';

$ACCESS_LEVEL = 1;

#  script to process subscription change

 $COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

$Acct_id = $COOKIE->{ACCT};
($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});

# print "Content-Type: text/plain\n\n";

read(STDIN, $Buffer, $ENV{'CONTENT_LENGTH'});

@pairs = split(/&/,$Buffer);

foreach $pair (@pairs) {

        ($Name, $Value) = split(/=/, $pair);

        $Value =~ tr/+/ /;
        $Value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C",hex($1))/eg;
        $Value =~ tr/\\//d;             #  Remove all back slashes
        $Value =~ s/(\'|\")/\\$1/g;
        $FORM{$Name} = $Value;
}

#  Get his current subscription (comsubref).  If notthing there then this is a new sub

$Companies = $dbh->prepare("select regemail,regusername from registrations where reg_id=$Reg_id");
$Companies->execute;
$Company = $Companies->fetchrow_hashref;
$Companies->finish;

($First_name,$Last_name) = split(/\s+/,$Company->{regusername});

if ($FORM{subaction} =~ /S/i) {

#  Set up JSON input

	$Text = sprintf<<EOD;
{
  "redirect_flows": {
    "description": "FreePlus Accounts",
    "session_token": "$Acct_id",
    "success_redirect_url": "https://www.freeplusaccounts.co.uk/cgi-bin/fpa/gclv2subs2.pl",
    "prefilled_customer": {
      "given_name": "$First_name",
      "family_name": "$Last_name",
      "email": "$Company->{regemail}"
    }
  }
}
EOD

#  Connect to GoCardless and set up the redirect flow

	$Text_length = length($Text);

	my $ua = LWP::UserAgent->new;
	my $req = HTTP::Request->new(POST => "https://api.gocardless.com/redirect_flows");

	$req->header('Content-Type' => 'application/json');
	$req->header('Content-Length' => $Text_length);
	$req->header('Accept' => 'application/json');
	$req->header('Authorization' => $Live_Auth);
	$req->header('GoCardless-Version' => '2015-07-06');
	$req->content($Text);

	my $res = $ua->request($req);

	$Res_content = from_json($res->content);
	$Url = $Res_content->{"redirect_flows"}->{"redirect_url"};
	$Flow = $Res_content->{"redirect_flows"}->{"id"};

	$Status = $dbh->do("update companies set comflowsref='$Flow',comsubtype='$FORM{sub}' where reg_id=$Reg_id and id=$Com_id");

#  Now head towards the URL given to us by GoCardless

	print<<EOD;
Content-Type: text/html
Status: 302
Location: $Url

EOD
}

#  Else it is a cancellation

elsif ($FORM{subaction} =~ /C/i) {

warn "Reg id = $Reg_id\tCom id = $Com_id\n";

	$Mantext = sprintf<<EOD;
{
  "data": {
    "metadata": {}
  }
}
EOD
	$Mantext_length = length($Mantext);
	$Companies = $dbh->prepare("select commandateref,date_format(comsubdue,'%d-%b-%y') as subdue,comsublevel from companies where reg_id=$Reg_id and id=$Com_id");
	$Companies->execute();
	$Company = $Companies->fetchrow_hashref;
	$Companies->finish;
	$Sts = $dbh->do("update companies set comsubtype='00' where id=$Com_id");

	my $ua4 = LWP::UserAgent->new;
warn "URL = https://api.gocardless.com/mandates/$Company->{commandateref}/actions/cancel\n";

	my $req4 = HTTP::Request->new(POST => "https://api.gocardless.com/mandates/$Company->{commandateref}/actions/cancel");

	$req4->header('Content-Type' => 'application/json');
	$req4->header('Content-Length' => $Mantext_length);
	$req4->header('Accept' => 'application/json');
	$req4->header('Authorization' => $Live_Auth);
	$req4->header('GoCardless-Version' => '2015-07-06');
	$req4->content($Mantext);
	my $res4 = $ua4->request($req4);
	$Res4_content = from_json($res4->content);

warn "res4 = $res4_content\n";

	$Vars = {
	 ads => $Adverts, cookie => $COOKIE,
		          title => 'Subscriptions',
			  cursub => $Sub_name[$Company->{comsublevel}],
			  subdue => $Company->{subdue},
		          membership => 'FreePlus Startup (FREE)',
		          company => $Company,
			  status => $Res4_content->{mandates}->{status}
	};

	use Template;
	$tt = Template->new({
	        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
	        WRAPPER => 'header.tt'
	});
	print "Content-Type: text/html\n\n";
	$tt->process('subs2_cancel.tt',$Vars);
}
$dbh->disconnect;
exit;
