#!/usr/bin/perl

$ACCESS_LEVEL = 1;

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});
use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");

unless ($COOKIE->{NO_ADS}) {
        require "/usr/local/git/fpa/cgi/display_adverts.ph";
        &display_adverts();
}

use CGI;
$Data = new CGI;
%FORM = $Data->Vars;

while (( $Key,$Value) = each %FORM) {
        $Value =~ tr/\\//d;
        $Value =~ s/\'/\\\'/g;
        $FORM{$Key} = $Value;
# warn "$Key = $Value\n";
}

@pairs = split(/&/,$FORM{state});

foreach $pair (@pairs) {

        ($Name, $Value) = split(/=/, $pair);
#        $Value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C",hex($1))/eg;
        $STATE{$Name} = $Value;
# warn "$Name = $Value\n";
}

#  First confirm the return

$Confirm = sprintf<<EOD;
{
  "resource_id": "$FORM{resource_id}",
  "resource_type": "$FORM{resource_type}"
}
EOD

$Confirm_length = length($Confirm);

use LWP::UserAgent;

my $ua = LWP::UserAgent->new;

$Merchant_id = '0205HPKCHY';
$App_key = '5hs3wSzzMuUarQFy_5Z2frezxymWhZK9dLEtkpDUBHBnjE7DjqJH1Js94MmR_6Fe';
my $req = HTTP::Request->new(POST => "https://sandbox.gocardless.com/api/v1/confirm");
$req->content_type('application/json');
$req->header('Accept' => 'application/json');
$req->header('Authorization' => 'bearer 8bztbuIDFtSTNPZTgQ1ELVa/XCRQqc04tldN/8L4PpvfT4SK4GS93vKw4hkj6tCM');
$req->authorization_basic('sRjngasG1PNtIT06u33yZMu7ftXDaDe4ARaXFY2U8FYaDc_bGLmV7UAIme9KZczj','5hs3wSzzMuUarQFy_5Z2frezxymWhZK9dLEtkpDUBHBnjE7DjqJH1Js94MmR_6Fe');
$req->header('Content-Length' => $Confirm_length );
$req->content($Confirm);

#  and get the response

my $res = $ua->request($req);

$Res_content = $res->content;

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
        WRAPPER => 'header.tt'
        });

if ($Res_content =~ /success/i) {
	($Reg_id,$Com_id) = split(/\+/,$STATE{id});

	$Membership[0] = '1';
	$Membership[1] = '3';
	$Membership[2] = '4';
	$Membership[3] = '5';
	$Membership[4] = '6';
	$Membership[5] = '8';

	$Memtext[0] = 'FreePlus Startup (FREE)';
	$Memtext[1] = 'FreePlus Bookkeeper Basic (&pound;5.00pm)';
	$Memtext[2] = 'FreePlus Standard (&pound;5.00pm)';
	$Memtext[3] = 'FreePlus Bookkeeper Standard (&pound;10.00pm)';
	$Memtext[4] = 'FreePlus Premium (&pound;10.00pm)';
	$Memtext[5] = 'FreePlus BookkeepersPremium (&pound;20.00pm)';

	$Sts = $dbh->do("update companies set comsublevel='$STATE{sublevel}',comsubdue='$STATE{subdue}',comsubref='$FORM{resource_id}',comcardref='$FORM{resource_uri}' where reg_id=$Reg_id and id=$Com_id");
	$Sts = $dbh->do("update registrations set regmembership='$Membership[$STATE{sublevel}]' where reg_id=$Reg_id");

#  Now get the details

	$Companies = $dbh->prepare("select comsublevel,date_format(comsubdue,'%D %M %Y') as subdue,comsubref from companies where reg_id=$Reg_id and id=$Com_id");
	$Companies->execute;
	$Company = $Companies->fetchrow_hashref;
	$Companies->finish;

	open(FILE,"</projects/tmp/$COOKIE->{COOKIE}");
	while (<FILE>) {
        	chomp($_);
	        ($Key,$Value) = split(/\t/,$_);
        	$DATA{$Key} = $Value;
	}
	close(FILE);

	$DATA{PLAN} = $Membership[$STATE{sublevel}];
	$DATA{ACCESS} = $Membership[$STATE{sublevel}];

	unlink("/projects/tmp/$COOKIE->{COOKIE}");

	open(FILE,">/projects/tmp/$COOKIE->{COOKIE}");
	while(($Key,$Value) = each %DATA) {
        	print FILE "$Key\t$Value\n";
	}
	close(FILE);

	$Cancellation = '';
	if ($STATE{cancellation} =~ /success/i) {
		$Cancellation = "<tr><td>Your previous subscription, reference:- <b>$STATE{cancel_id}</b> has been cancelled</td></tr>";
	}
	elsif ($STATE{cancellation} =~ /failure/i) {
		$Cancellation = "<tr><td>We have been unable to cancel your previous subscription, reference:- <b>$STATE{cancel_id}</b> for some reason.&nbsp;&nbsp;Please cancel it directly with your bank.&nbsp;&nbsp;If you have any problems please contact us quoting this reference number.</td></tr>";
	}

	$Vars = { cookie => $COOKIE,
          title => 'Subscriptions',
          membership => $Memtext[$STATE{sublevel}],
	  cancellation => $Cancellation,
          company => $Company
	};

	print "Content-Type: text/html\n\n";
	$tt->process('subs_return.tt',$Vars);
}

$dbh->disconnect;
# use DBI;

exit;

