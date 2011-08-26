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

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");
unless ($COOKIE->{NO_ADS}) {
	require "/usr/local/git/fpa/cgi/display_adverts.ph";
	&display_adverts();
}

$Customers = $dbh->prepare("select id,cusname,cusaddress,cuspostcode,cusregion,cuscontact,cusemail,custerms,cusdefpo from customers where id=$FORM{id} and acct_id='$COOKIE->{ACCT}'");
$Customers->execute;
@Customer = $Customers->fetchrow;

for ($i=0;$i<8;$i++) {
	$Customer[$i] =~ tr/\r//d;
	$Customer[$i] =~ s/\n/\\n/sg;
}

print<<EOD;
Content-Type: application/json

{ 
  "id": "$Customer[0]",  
  "cusname": "$Customer[1]",  
  "cusaddress": "$Customer[2]",  
  "cuspostcode": "$Customer[3]", 
  "cusregion": "$Customer[4]",  
  "cuscontact": "$Customer[5]", 
  "cusemail": "$Customer[6]",  
  "custerms": "$Customer[7]",  
  "cusdefpo": "$Customer[8]"  
}  
EOD

$Customers->finish;
$dbh->disconnect;
exit;
