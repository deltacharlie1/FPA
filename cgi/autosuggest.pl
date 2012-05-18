#!/usr/bin/perl

$ACCESS_LEVEL = 1;

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

@pairs = split(/&/,$ENV{QUERY_STRING});

foreach $pair (@pairs) {

        ($Name, $Value) = split(/=/, $pair);

        $Value =~ tr/+/ /;
        $Value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C",hex($1))/eg;
        $FORM{$Name} = $Value;
}

#  Script to test autosuggest

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");
unless ($COOKIE->{NO_ADS}) {
	require "/usr/local/git/fpa/cgi/display_adverts.ph";
	&display_adverts();
}

if ($FORM{type} =~ /^Sales/i) {
	$Customers = $dbh->prepare("select id,invinvoiceno from invoices where invinvoiceno like '$FORM{term}%' and invtype in ('S','C') and acct_id='$COOKIE->{ACCT}' order by invinvoiceno");
}
elsif ($FORM{type} =~ /^Purchase/i) {
	$Customers = $dbh->prepare("select id,invinvoiceno from invoices where invinvoiceno like '$FORM{term}%' and invtype in ('P','R') and acct_id='$COOKIE->{ACCT}' order by invinvoiceno");
}
elsif ($FORM{type} =~ /^Supplier/i) {
	$Customers = $dbh->prepare("select id,substring(cusname,1,30),cusdefcoa,cusdefvatrate from customers where cusname like '$FORM{term}%' and cussupplier='Y' and cusname<>'Unlisted' and cussuppress='N' and acct_id='$COOKIE->{ACCT}' order by cusname");
}
elsif ($FORM{type} =~ /^Customer/i) {
	$Customers = $dbh->prepare("select id,substring(cusname,1,30),cusdefpaymethod,cusdefvatrate,cuscis from customers where cusname like '$FORM{term}%' and cussales='Y' and cusname<>'Unlisted' and cussuppress='N' and acct_id='$COOKIE->{ACCT}' order by cusname");
}
else {
	$Customers = $dbh->prepare("select id,substring(cusname,1,30),cusdefpaymethod,cusdefvatrate,cuscis from customers where cusname like '$FORM{term}%' and cusname<>'Unlisted' and cussuppress='N' and acct_id='$COOKIE->{ACCT}' order by cusname");
}
$Customers->execute;

$Rws = $Customers->rows;

print "Content-Type: application/json\n\n";
$JSON = "[ ";

while (@Customer = $Customers->fetchrow) { 
	$JSON .= "{\"label\":\"$Customer[1]\",\"value\":\"$Customer[1]\",\"id\":\"$Customer[0]\",\"coa\":\"$Customer[2]\",\"vatrate\":\"$Customer[3]\",\"cuscis\":\"$Customer[4]\"}, ";
}
$JSON =~ s/, $/  /;
$JSON .=  "]";

print $JSON;
$Customers->finish;
$dbh->disconnect;
exit;
