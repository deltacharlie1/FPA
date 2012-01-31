#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to update Company Details

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

use CGI;
use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");

$Data = new CGI;
%FORM = $Data->Vars;

while (( $Key,$Value) = each %FORM) {

#  Remove any bad characters

	$Value =~ tr/\\//d;
	$Value =~ s/\'/\\\'/g;
        $FORM{$Key} = $Value;

}

warn "$FORM{stmtdata}\n";

$FORM{stmtdata} =~ tr/\r\n//d;

$FORM{stmtdata} =~ s/^.*?<tbody.*?>(.*)?<\/tbody.*$/$1/i;

print<<EOD;
Content-Type: text/html
Status: 200 OK

EOD
$dbh->disconnect;
exit;
