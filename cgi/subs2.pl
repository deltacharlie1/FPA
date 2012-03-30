#!/usr/bin/perl

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

$Merchant_id = '0205HPKCHY';
$App_key = '5hs3wSzzMuUarQFy_5Z2frezxymWhZK9dLEtkpDUBHBnjE7DjqJH1Js94MmR_6Fe';

#  Get his current subscription (comsubref).  If notthing there then this is a new sub

use CGI;

$Companies = $dbh->prepare("select comsublevel,comsubref,regemail,regusername from companies left join registrations using (reg_id) where reg_id=$Reg_id and id=$Com_id");
$Companies->execute;
$Company = $Companies->fetchrow_hashref;
$Companies->finish;
$dbh->disconnect;

($First_name,$Last_name) = split(/\s+/,$Company->{regusername});
$First_name = CGI::escape($First_name);
$Last_name = CGI::escape($Last_name);
$Company->{regemail} = CGI::escape($Company->{regemail});

$Start_date = `date --date="1 week" +%Y-%m-%dT%T%Z`;
chomp($Start_date);
$Start_date =~ s/:/\%3A/g;

$Subdue = $Start_date;
$Subdue =~ s/T*$//;

$State = "id=$COOKIE->{ACCT}&sublevel=$FORM{sub}&subdue=$Subdue";
$State = CGI::escape($State);

#  Set up strings to send to GCL

@Sub_name=("FreePlus%20Free%20Edition","Bookkeeper%20Basic","FreePlus%20Standard","Bookkeeper%20Standard","FreePlus%20Premium","Bookkeeper%20Premium");
@Sub_amt = ("0.00","5.00","5.00","10.00","10.00","20.00");

if ($FORM{subaction} =~ /S/i) {
	if ($Company->{comsubref}) {	#  Already a subscriber so just change subscription level (if different from existing
		if ($Company->{comsublevel} != $FORM{sub}) {
			print<<EOD;
Content-Type: text/plain

No Change!

Sublevel = $Company->{comsublevel}

New Sub = $FORM{sub}
EOD
		}
		else {
			print<<EOD;
Content-Type: text/plain

Subscription Changed

Sublevel = $Company->{comsublevel}

New Sub = $FORM{sub}
EOD
		}
	}
	else {				#  New subscriber so connect ot the Connect API

#  Set up the parameters

		use Digest::SHA qw(hmac_sha256_hex);

		$client_id = 'sRjngasG1PNtIT06u33yZMu7ftXDaDe4ARaXFY2U8FYaDc_bGLmV7UAIme9KZczj';
		$nonce = 'fpa'.$$;
		$timestamp = `date +%Y-%m-%dT%T%Z`;
		chomp($timestamp);
		$timestamp =~ s/:/\%3A/g;

		$Sub_text = "client_id=$client_id&nonce=$nonce&state=$State&subscription%5Bamount%5D=$Sub_amt[$FORM{sub}]&subscription%5Binterval_length%5D=1&subscription%5Binterval_unit%5D=month&subscription%5Bmerchant_id%5D=$Merchant_id&subscription%5Bname%5D=$Sub_name[$FORM{sub}]&subscription%5Bstart_at%5D=$Start_date&subscription%5Buser%5D%5Bemail%5D=$Company->{regemail}&subscription%5Buser%5D%5Bfirst_name%5D=$First_name&subscription%5Buser%5D%5Blast_name%5D=$Last_name&timestamp=$timestamp";

		$Signature = hmac_sha256_hex( $Sub_text, $App_key );

		print<<EOD;
Content-Type: text/html
Status: 302
Location: https://sandbox.gocardless.com/connect/subscriptions/new?client_id=$client_id&nonce=$nonce&signature=$Signature&$Sub_text

EOD
	}
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
	my $req = HTTP::Request->new(PUT => "https://sandbox.gocardless.com/api/v1/subscriptions/$Company->{comsubref}/cancel");
	$req->header('Content-Type' => 'text/plain');
	$req->header('Content-Length' => '0');
	$req->header('Accept' => 'application/xml');
	$req->header('Authorization' => 'bearer 8bztbuIDFtSTNPZTgQ1ELVa/XCRQqc04tldN/8L4PpvfT4SK4GS93vKw4hkj6tCM');

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
exit;
sub update_cookiefile {

warn "cookie = $COOKIE->{COOKIE}\n";

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

