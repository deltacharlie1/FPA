#!/usr/bin/perl

use CGI;
use DBI;

$Data = new CGI;
%FORM = $Data->Vars;

while (( $Key,$Value) = each %FORM) {

#  Remove any bad characters

	$Value =~ tr/\\//d;
	$Value =~ s/\'/\\\'/g;
        $FORM{$Key} = $Value;
}
open(FILE,">>/tmp/upload.txt");
print FILE "Upload called";
close(FILE);

print<<EOD;
Content-Type: text/json

{ "success": false, "error": "Invalid Because Doug said!" }
EOD

exit;
