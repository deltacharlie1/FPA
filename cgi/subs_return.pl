#!/usr/bin/perl

$Facility = `cat /usr/local/git/fpa/other/.gocardless`;
chomp($Facility);
if ($Facility =~ /live/i) {
        $Client_id = 'L4s4jrtE8p0B9X2LOTxR_aE4V_rBNjyZEkkhBFlVV9Lhv2MYIISOuFGDhL6z2baD';                #  App identifief
        $App_key = 'eTzWcFjDjsPpd_GhwWBH4ovB_MyYQJDr5snpHOeEohF6uamIVWMnLUE2yJ_Cfl_A';                  #  App secret
        $Authorization = 'bearer 7koL7/6N7eexnQeYyZz24/r7pevUuO1tA6ZH+A0SjX0pDV42z/YXodG5KuIUdKfm';     #  Merchant access token
        $Merchant_id = '0265HC17QC';                                                                    #  Merchant id
	$Dom = '';
}
else {
        $Client_id = 'sRjngasG1PNtIT06u33yZMu7ftXDaDe4ARaXFY2U8FYaDc_bGLmV7UAIme9KZczj';                #  App identifier
        $App_key = '5hs3wSzzMuUarQFy_5Z2frezxymWhZK9dLEtkpDUBHBnjE7DjqJH1Js94MmR_6Fe';                  #  App secret
        $Authorization = 'bearer 8bztbuIDFtSTNPZTgQ1ELVa/XCRQqc04tldN/8L4PpvfT4SK4GS93vKw4hkj6tCM';     #  Merchant access token
        $Merchant_id = '0205HPKCHY';                                                                    #  Merchant Id
	$Dom = 'sandbox.';
}

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

my $req = HTTP::Request->new(POST => "https://".$Dom."gocardless.com/api/v1/confirm");
$req->content_type('application/json');
$req->header('Accept' => 'application/json');
$req->header('Authorization' => $Authorization);
$req->authorization_basic($Client_id,$App_key);
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

	$Sts = $dbh->do("update companies set comsublevel='$STATE{sublevel}',comsubdue=date_add('$STATE{subdue}',interval 2 day),comsubref='$FORM{resource_id}',comcardref='$FORM{resource_uri}' where reg_id=$Reg_id and id=$Com_id");
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
else {
	print<<EOD;
Content-Type: text/plain

Unsuccessful return for subs_return

EOD
}
$dbh->disconnect;
# use DBI;

exit;

