#!/usr/bin/perl

#  This is the app run once the user has returned from the GoCardless redirect flow

($Key,$Flow) = split(/=/,$ENV{QUERY_STRING});

use CGI;
use JSON;
use LWP::UserAgent;
use DBI;

#  0  -  FreePlus Free (£0pm)
#  1  -  Freeplus Basic (Bookeeper) (£5.50)
#  2  -  Freeplus Standard (£5.5-)
#  3  -  Freeplus Standard Bookkeeper (£10)
#  4  -  Freeplus Premium  (£10)
#  5  -  Freeplus Premium Bookkeeper  (£20)

#  Set up strings to send to GCL

@Sub_name=("FreePlus Free Edition","Bookkeeper Basic","FreePlus Standard","Bookkeeper Standard","FreePlus Premium","Bookkeeper Premium");
@Sub_amt = ("000","660","660","1200","1200","2400");
@Sub_mem=("1","3","4","5","6","8");
$Success = 0;

my $Authorization = 'Bearer sandbox_IGUCdnZP_2i58W518rZnAmQmGwiBwrGAqGQRnhSU';
my $Live_Auth = 'Bearer live_m2elMSXaTSObKqlTGBGTmy3aMivybF94fROuZCej';

$dbh = DBI->connect("DBI:mysql:fpa");
$Companies = $dbh->prepare("select id,reg_id,comflowsref,comsubtype from companies where comflowsref='$Flow'");
$Companies->execute();
$Company = $Companies->fetchrow_hashref;
$Companies->finish;
$Reg_id = $Company->{reg_id};
$Com_id = $Company->{id};
$Subtype = $Company->{comsubtype};

###  Complete the New Customer process

$Text = sprintf<<EOD;
{
  "data": {
    "session_token": "$Reg_id+$Com_id"
  }
}
EOD
$Text_length = length($Text);

my $ua1 = LWP::UserAgent->new;
my $req1 = HTTP::Request->new(POST => "https://api.gocardless.com/redirect_flows/$Flow/actions/complete");

$req1->header('Content-Type' => 'application/json');
$req1->header('Content-Length' => $Text_length);
$req1->header('Accept' => 'application/json');
$req1->header('Authorization' => $Live_Auth);
$req1->header('GoCardless-Version' => '2015-07-06');
$req1->content($Text);

my $res1 = $ua1->request($req1);

$Res1_content = from_json($res1->content);

###  ... and get the Customer ID and Mandate ID

$Cusid = $Res1_content->{"redirect_flows"}->{"links"}->{"customer"};
$Manid = $Res1_content->{"redirect_flows"}->{"links"}->{"mandate"};

###  Set up a subscrittion starting one month from now

my $Start_date = `date +%F --date='next month - 20 day'`;
chomp($Start_date);

$Subtext = sprintf<<EOD;
{
  "subscriptions": {
    "amount": $Sub_amt[$Subtype],
    "currency": "GBP",
    "name": "$Sub_name[$Subtype]",
    "interval_unit": "monthly",
    "start_date":  "$Start_date",
    "links": {
      "mandate": "$Manid"
    }
  }
}
EOD
$Subtext_length = length($Subtext);
my $ua2 = LWP::UserAgent->new;
my $req2 = HTTP::Request->new(POST => "https://api.gocardless.com/subscriptions");

$req2->header('Content-Type' => 'application/json');
$req2->header('Content-Length' => $Subtext_length);
$req2->header('Accept' => 'application/json');
$req2->header('Authorization' => $Live_Auth);
$req2->header('GoCardless-Version' => '2015-07-06');
$req2->content($Subtext);

my $res2 = $ua2->request($req2);
if ($res2->is_success) {

	$Success = 1;

#  1.  See if we need to create a docs directory
#  2.  See if there is an existing subscription which needs to be cancelled
#  3.  Create an immediate payment

	$Companies = $dbh->prepare("select comdocsdir,commandateref from companies where reg_id=$Reg_id and id=$Com_id");
	$Companies->execute();
	$Company = $Companies->fetchrow_hashref;
	$Companies->finish();

        unless ($Company->{comdocsdir}) {	#  New subscriber so create docs dir
                use Digest::MD5;
                $Docsdir = Digest::MD5->new;
                $Docsdir->add($$.$COOKIE->{ID});
                $Company->{comdocsdir} = $Docsdir->hexdigest;
                $Sts = $dbh->do("update companies set comdocsdir='$Company->{comdocsdir}' where reg_id=$Reg_id and id=$Com_id");
                mkdir("/projects/fpa_docs/".$Company->{comdocsdir});
        }

	if ($Company->{commandateref}) {	#  Existing subscriber so cancel subscription

		$Mantext = sprintf<<EOD;
{
  "data": {
    "metadata": {}
  }
}
EOD
		$Mantext_length = length($Mantext);

		my $ua4 = LWP::UserAgent->new;
		my $req4 = HTTP::Request->new(POST => "https://api.gocardless.com/mandates/$Company->{commandateref}/actions/cancel");

		$req4->header('Content-Type' => 'application/json');
		$req4->header('Content-Length' => $Mantext_length);
		$req4->header('Accept' => 'application/json');
		$req4->header('Authorization' => $Live_Auth);
		$req4->header('GoCardless-Version' => '2015-07-06');
		$req4->content($Mantext);
		my $res4 = $ua4->request($req4);

#		warn "Mandate return = ".$res4->decoded_content."\n\n";
#		$Res4_content = from_json($res4->content);
	}

	$Res2_content = from_json($res2->content);
	$Subid = $Res2_content->{"subscriptions"}->{"id"};
	$Start = $Res2_content->{"subscriptions"}->{"start_date"};

###  Set up an initial payment for the first month for as soon as possible
	$Paytext = sprintf<<EOD;
{
  "payments": {
    "amount": $Sub_amt[$Subtype],
    "currency": "GBP",
    "description":  "$Sub_name[$Subtype] Initial Payment",
    "links": {
      "mandate": "$Manid"
    }
  }
}
EOD

	$Paytext_length = length($Paytext);
	my $ua3 = LWP::UserAgent->new;
	my $req3 = HTTP::Request->new(POST => "https://api.gocardless.com/payments");

	$req3->header('Content-Type' => 'application/json');
	$req3->header('Content-Length' => $Paytext_length);
	$req3->header('Accept' => 'application/json');
	$req3->header('Authorization' => $Live_Auth);
	$req3->header('GoCardless-Version' => '2015-07-06');
	$req3->content($Paytext);

	my $res3 = $ua3->request($req3);

	$Res3_content = from_json($res3->content);
	$Payid = $Res3_content->{"payments"}->{"id"};
	$Paydate = $Res3_content->{"payments"}->{"charge_date"};
	$Paystatus = $res3->status_line();

	$Pdate = `date -d $Paydate +'%d %b %Y'`;
	($D,$M,$Y) = split(/ /,$Pdate);

	my $suffix;
	if    ($D =~ /(?<!1)1$/) { $suffix = 'st'; }
	elsif ($D =~ /(?<!1)2$/) { $suffix = 'nd'; }
	elsif ($D =~ /(?<!1)3$/) { $suffix = 'rd'; }
	else                     { $suffix = 'th'; }
	$D =~ s/^0//;
	$Pdate = $D.$suffix." ".$M." ".$Y;

	$D = `date -d $Start +%d`;
	chomp($D);

	if    ($D =~ /(?<!1)1$/) { $suffix = 'st'; }
	elsif ($D =~ /(?<!1)2$/) { $suffix = 'nd'; }
	elsif ($D =~ /(?<!1)3$/) { $suffix = 'rd'; }
	else                     { $suffix = 'th'; }
	$D =~ s/^0//;
	$D .= $suffix;

#  Update the subscription level in companies and registrations
#
	$Sts = $dbh->do("update companies set comsublevel='$Subtype',comsubdue=date_add('$Paydate',interval 3 day),comcusref='$Cusid',commandateref='$Manid',comsubref='$Subid',compayref='$Payid',comflowsref='' where reg_id=$Reg_id and id=$Com_id");

	$Sts = $dbh->do("update registrations set regmembership='$Sub_mem[$Subtype]' where reg_id=$Reg_id");
}
$dbh->disconnect;
$Sub_amt[$Subtype] =~ s/(\d+)(\d\d)/$1\.$2/;

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
	WRAPPER => 'header.tt'
        });

$Vars = {
	success => $Success,
	subtitle => $Sub_name[$Subtype],
	subamt => $Sub_amt[$Subtype],
	firstpayment => $Pdate,
	recpayment => $D,
	  javascript => '<style type="text/css">
.subblock { background-color: #dee5d2; }
</style>'
};

print "Content-Type: text/html\n\n";
$tt->process('testreturns.tt',$Vars);

exit;
print<<EOD;
Content-Type: text/plain
Status: 200 OK

Customer ID = $Cusid
Mandate ID = $Manid
Subscription ID = $Subid

First Payment ID = $Payid
First Payment Date = $DPay
and thereafter on or asbout the $D$suffix day of each month

Pay Status = $Paystatus
EOD
exit;

