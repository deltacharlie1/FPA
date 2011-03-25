#!/usr/bin/perl

$ACCESS_LEVEL = 1;

print "Content-Type: text/plain\n\n";
print "Hi there\n";

#use Checkid;
# $COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

use CGI;
$Data = new CGI;
%FORM = $Data->Vars;

while (( $Key,$Value) = each %FORM) {

#  Remove any bad characters

        $Value =~ tr/\\//d;
        $Value =~ s/\'/\\\'/g;
        $FORM{$Key} = $Value;

 print "$Key = $Value\n";
}
 exit;

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");
$Customers = $dbh->prepare("select id,cusname,cusaddress,cuspostcode,cusregion,cuscontact,cusemail,custerms,cusdefpo from customers where cusname like '$FORM{q}%' and cussales='Y' and id=$ENV{QUERY_STRING} and acct_id='$COOKIE->{ACCT}' order by cusname");
$Customers->execute;
@Customer = $Customers->fetchrow;

$Customer[2] =~ s/\n/\\n/sg;

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
