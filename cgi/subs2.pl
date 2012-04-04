#!/usr/bin/perl

$Facility = `cat /usr/local/git/fpa/other/.gocardless`;
chomp($Facility);
if ($Facility =~ /live/i) {
	$Client_id = 'L4s4jrtE8p0B9X2LOTxR_aE4V_rBNjyZEkkhBFlVV9Lhv2MYIISOuFGDhL6z2baD';		#  App identifief
	$App_key = 'eTzWcFjDjsPpd_GhwWBH4ovB_MyYQJDr5snpHOeEohF6uamIVWMnLUE2yJ_Cfl_A';			#  App secret
	$Authorization = 'bearer 7koL7/6N7eexnQeYyZz24/r7pevUuO1tA6ZH+A0SjX0pDV42z/YXodG5KuIUdKfm';	#  Merchant access token
	$Merchant_id = '0265HC17QC';									#  Merchant id
	$Dom = '';
}
else {
	$Client_id = 'sRjngasG1PNtIT06u33yZMu7ftXDaDe4ARaXFY2U8FYaDc_bGLmV7UAIme9KZczj';		#  App identifier
	$App_key = '5hs3wSzzMuUarQFy_5Z2frezxymWhZK9dLEtkpDUBHBnjE7DjqJH1Js94MmR_6Fe';			#  App secret
	$Authorization = 'bearer 8bztbuIDFtSTNPZTgQ1ELVa/XCRQqc04tldN/8L4PpvfT4SK4GS93vKw4hkj6tCM';	#  Merchant access token
	$Merchant_id = '0205HPKCHY';									#  Merchant Id
	$Dom = 'sandbox.';
}

$ACCESS_LEVEL = 1;

#  script to process subscription change

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);
use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");

unless ($COOKIE->{NO_ADS}) {
        require "/usr/local/git/fpa/cgi/display_adverts.ph";
        &display_adverts();
}

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
# warn "$Name = $Value\n";
}

#  Get his current subscription (comsubref).  If notthing there then this is a new sub

use CGI;

$Companies = $dbh->prepare("select comsublevel,comsubref,regemail,regusername,comsubdue,datediff(comsubdue,now()) as daysbeforedue,date_add(comsubdue,interval 1 month) as subnextdue from companies left join registrations using (reg_id) where reg_id=$Reg_id and id=$Com_id");
$Companies->execute;
$Company = $Companies->fetchrow_hashref;
$Companies->finish;

($First_name,$Last_name) = split(/\s+/,$Company->{regusername});
$First_name = CGI::escape($First_name);
$Last_name = CGI::escape($Last_name);
$Company->{regemail} = CGI::escape($Company->{regemail});

$Start_date = `date --date="1 week" +%Y-%m-%dT%T%Z`;
chomp($Start_date);
$Start_date =~ s/:/\%3A/g;

#  Set up strings to send to GCL

@Sub_name=("FreePlus%20Free%20Edition","Bookkeeper%20Basic","FreePlus%20Standard","Bookkeeper%20Standard","FreePlus%20Premium","Bookkeeper%20Premium");
@Sub_amt = ("0.00","5.00","5.00","10.00","10.00","20.00");

$Url = "connect/subscriptions/new";

if ($FORM{subaction} =~ /S/i) {
	if ($Company->{comsubref} && $Company->{comsublevel} != $FORM{sub}) {	#  Already a subscriber so  first cancel the existing one
		$Url = "users/sign_in";
$Url = "connect/subscriptions/new";

#  Calculate the next subscription due date

		if ($Company->{daysbeforedue} < 3 && $Company->{daysbeforedue} >= 0) {

#  sustitute nextsubdue date (because he will most likley already be committed to this month's sub)

			$Start_date =~ s/^\d\d\d\d-\d\d-\d\d/$Company->{subnextdue}/;
		}
		else {
			$Start_date =~ s/^\d\d\d\d-\d\d-\d\d/$Company->{comsubdue}/;
		}

		$Subdue = $Start_date;
		$Subdue =~ s/T*$//;

		$State = "id=$COOKIE->{ACCT}&sublevel=$FORM{sub}&subdue=$Subdue";

		use LWP::UserAgent;
	
		my $ua = LWP::UserAgent->new;
		my $req = HTTP::Request->new(PUT => "https://".$Dom."gocardless.com/api/v1/subscriptions/$Company->{comsubref}/cancel");
		$req->header('Content-Type' => 'text/plain');
		$req->header('Content-Length' => '0');
		$req->header('Accept' => 'application/xml');
		$req->header('Authorization' => $Authorization);

		my $res = $ua->request($req);

		$Res_content = $res->content;
		if ($Res_content =~ /<status.*>cancelled<\/status>/is) {
			$State .= "&cancellation=success&cancel_id=$Company->{comsubref}";
		}
		else {
			$State .= "&cancellation=failure&cancel_id=$Company->{comsubref}";
		}
	}
	else {

		$Subdue = $Start_date;
		$Subdue =~ s/T*$//;

		$State = "id=$COOKIE->{ACCT}&sublevel=$FORM{sub}&subdue=$Subdue";
	}

#  Set up the parameters

	use Digest::SHA qw(hmac_sha256_hex);
	$State = CGI::escape($State);

	$nonce = 'fpa'.$$;
	$timestamp = `date +%Y-%m-%dT%T%Z`;
	chomp($timestamp);
	$timestamp =~ s/:/\%3A/g;

	$Sub_text = "client_id=$Client_id&nonce=$nonce&state=$State&subscription%5Bamount%5D=$Sub_amt[$FORM{sub}]&subscription%5Binterval_length%5D=1&subscription%5Binterval_unit%5D=month&subscription%5Bmerchant_id%5D=$Merchant_id&subscription%5Bname%5D=$Sub_name[$FORM{sub}]&subscription%5Bstart_at%5D=$Start_date&subscription%5Buser%5D%5Bemail%5D=$Company->{regemail}&subscription%5Buser%5D%5Bfirst_name%5D=$First_name&subscription%5Buser%5D%5Blast_name%5D=$Last_name&timestamp=$timestamp";

	$Signature = hmac_sha256_hex( $Sub_text, $App_key );

	print<<EOD;
Content-Type: text/html
Status: 302
Location: https://${Dom}gocardless.com/$Url?client_id=$Client_id&nonce=$nonce&signature=$Signature&$Sub_text

EOD
}
elsif ($FORM{subaction} =~ /C/i) {

	$Memtext[1] = 'FreePlus Startup (FREE)';
	$Memtext[3] = 'FreePlus Bookkeeper Basic (&pound;5.00pm)';
	$Memtext[4] = 'FreePlus Standard (&pound;5.00pm)';
	$Memtext[5] = 'FreePlus Bookkeeper Standard (&pound;10.00pm)';
	$Memtext[6] = 'FreePlus Premium (&pound;10.00pm)';
	$Memtext[8] = 'FreePlus BookkeepersPremium (&pound;20.00pm)';

#  Get the subscription details (resource id)

	$Companies = $dbh->prepare("select comsubref,comsublevel,date_format(comsubdue,'%D %M %Y') as comsubdue from companies where reg_id=$Reg_id and id=$Com_id");
	$Companies->execute;
	$Company = $Companies->fetchrow_hashref;
	$Companies->finish;

	use LWP::UserAgent;

	my $ua = LWP::UserAgent->new;
	my $req = HTTP::Request->new(PUT => "https://".$Dom."gocardless.com/api/v1/subscriptions/$Company->{comsubref}/cancel");
	$req->header('Content-Type' => 'text/plain');
	$req->header('Content-Length' => '0');
	$req->header('Accept' => 'application/xml');
	$req->header('Authorization' => $Authorization);

	my $res = $ua->request($req);

	$Res_content = $res->content;
	if ($Res_content =~ /<status.*>cancelled<\/status>/is) {
        	$Status = "cancelled";
		$Sts = $dbh->do("update companies set comsublevel='00',comsubtype='',comsubref='',commerchantref='',comcardref='',compt_logo='2010-01-01',comuplds=0,comno_ads='2010-01-01' where reg_id=$Reg_id and id=$Com_id");
		$Sts = $dbh->do("update registrations set regmembership='1' where reg_id=$Reg_id");

		$Vars = { cookie => $COOKIE,
		          title => 'Subscriptions',
		          membership => 'FreePlus Startup (FREE)',
		          company => $Company,
			  status => 'cancelled'
		};
		&update_cookiefile;
	}
	else {
        	$Status =  "uncancelled";
		$Vars = { cookie => $COOKIE,
		          title => 'Subscriptions',
		          membership => $Memtext[$Company->{comsublevel}],
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

