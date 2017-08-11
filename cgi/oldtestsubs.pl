#!/usr/bin/perl

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

@Sub_amt = ("000","6.00","6.00","12.00","12.00","24.00");

my $dbh = DBI->connect("DBI:mysql:fpa2");

my $Authorization = 'Bearer sandbox_IGUCdnZP_2i58W518rZnAmQmGwiBwrGAqGQRnhSU';

$ACCESS_LEVEL = 1;

#  script to process subscription change

 $COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

$Acct_id = $COOKIE->{ACCT};
($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});

# print "Content-Type: text/plain\n\n";

read(STDIN, $Buffer, $ENV{'CONTENT_LENGTH'});

@pairs = split(/&/,$Buffer);

warn "Starting 1 ...";

foreach $pair (@pairs) {

        ($Name, $Value) = split(/=/, $pair);

        $Value =~ tr/+/ /;
        $Value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C",hex($1))/eg;
        $Value =~ tr/\\//d;             #  Remove all back slashes
        $Value =~ s/(\'|\")/\\$1/g;
        $FORM{$Name} = $Value;
}

#  Get his current subscription (comsubref).  If notthing there then this is a new sub

$Companies = $dbh->prepare("select comdocsdir,comsublevel,comsubref,regemail,regusername,comsubdue,datediff(comsubdue,now()) as daysbeforedue,date_add(comsubdue,interval 1 month) as subnextdue from companies left join registrations using (reg_id) where reg_id=$Reg_id and id=$Com_id");
$Companies->execute;
$Company = $Companies->fetchrow_hashref;
$Companies->finish;

($First_name,$Last_name) = split(/\s+/,$Company->{regusername});

#####  First cancel all existing subscriptions

#  Get any existing mandate from gcls

$Gcls = $dbh->prepare("select gclmanid from gcls where acct_id='$Acct_id'");
$Gcls->execute();
if ($Gcls->rows > 0) {
	@Gcl = $Gcls->fetchrow;

	$Text = sprintf<<EOD;
{
  "data": {
    "metadata": {}
  }
}
EOD

	$Text_length = length($Text);

	my $ua = LWP::UserAgent->new;
	my $req = HTTP::Request->new(POST => "https://api-sandbox.gocardless.com/mandates/$Gcl[0]/actions/cancel");

	$req->header('Content-Type' => 'application/json');
	$req->header('Content-Length' => $Text_length);
	$req->header('Accept' => 'application/json');
	$req->header('Authorization' => $Authorization);
	$req->header('GoCardless-Version' => '2015-07-06');
	$req->content($Text);

	my $res = $ua->request($req);
	$Res_content = from_json($res->content);
	$CancelStatus = $Res_content->{"mandates"}->{"status"};

	$Status = $dbh->do("delete from gcls where acct_id='$Acct_id'");

warn "Mandate cancellation status for $Gcl[0] - $CancelStatus";
}

##############  Remember to change T to S!!

if ($FORM{subaction} =~ /T/i) {

#  first see if we need to create a new directory

	unless ($Company->{comdocsdir}) {
		use Digest::MD5;
	        $Docsdir = Digest::MD5->new;
	        $Docsdir->add($$.$COOKIE->{ID});
	        $Company->{comdocsdir} = $Docsdir->hexdigest;
	        $Sts = $dbh->do("update companies set comdocsdir='$Company->{comdocsdir}' where reg_id=$Reg_id and id=$Com_id");
        	mkdir("/projects/fpa_docs/".$Company->{comdocsdir});
	}

#  Set up JSON input

	$Text = sprintf<<EOD;
{
  "redirect_flows": {
    "description": "FreePlus Accounts",
    "session_token": "$Acct_id",
    "success_redirect_url": "https://www.freeplusaccounts.co.uk/cgi-bin/fpa/newsubs2.pl",
    "prefilled_customer": {
      "given_name": "$First_name",
      "family_name": "$Last_name",
      "email": "doug.conran49\@googlemail.com"
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

	$Status = $dbh->do("insert into gcls (acct_id,gclflow,gclsub,gclamt) values ('$Acct_id','$Flow','$FORM{sub}','$Sub_amt[$FORM{sub}]')");
	$dbh->disconnect;


	print<<EOD;
Content-Type: text/html
Status: 302
Location: $Url

EOD
}
elsif ($FORM{subaction} =~ /X/i) {

	if ($CancelStatus =~ /cancel/i) {
		$Sts = $dbh->do("update companies set comsublevel='00',comsubtype='',comsubref='',commandateref='',compayref='',compt_logo='2010-01-01',comuplds=0,comno_ads='2010-01-01' where reg_id=$Reg_id and id=$Com_id");
		$Sts = $dbh->do("update registrations set regmembership='1' where reg_id=$Reg_id");

		$Vars = {
	 ads => $Adverts, cookie => $COOKIE,
		          title => 'Subscriptions',
		          membership => 'FreePlus Startup (FREE)',
		          company => $Company,
			  status => 'cancelled'
		};
	}
	else {
        	$Status =  "uncancelled";
		$Vars = {
	 ads => $Adverts, cookie => $COOKIE,
		          title => 'Subscriptions',
		          membership => 'Unchanged',
		          company => $Company,
			  status => 'uncancelled'
		};
	}

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
sub update_cookiefile {

open(FILE,"</projects/tmp/$COOKIE->{COOKIE}");
while (<FILE>) {
        chomp($_);
        ($Key,$Value) = split(/\t/,$_);
        $DATA{$Key} = $Value;
}
close(FILE);

$DATA{PLAN} = '1';
$DATA{ACCESS} = '1';

unlink("/projects/tmp/$COOKIE->{COOKIE}");

open(FILE,">/projects/tmp/$COOKIE->{COOKIE}");
while(($Key,$Value) = each %DATA) {
        print FILE "$Key\t$Value\n";
}
close(FILE);
}
exit;
