#!/usr/bin/perl

warn "subs_validate = \n";
print "Content-Type: text/plain\n\n";

use CGI;
$Data = new CGI;
%FORM = $Data->Vars;

while (( $Key,$Value) = each %FORM) {

        $Value =~ tr/\\//d;
        $Value =~ s/\'/\\\'/g;
        $FORM{$Key} = $Value;
print "$Key = $Value\n";
warn "$Key = $Value\n";

}
exit;

