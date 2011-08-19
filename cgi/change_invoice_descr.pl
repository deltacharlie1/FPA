#!/usr/bin/perl

#  Script to change an errorneously entered nominal code.  Called from coa_drill_down

use CGI;

$ACCESS_LEVEL = 1;

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

$Data = new CGI;
%FORM = $Data->Vars;

while (( $Key,$Value) = each %FORM) {

#  Remove any bad characters

        $Value =~ tr/\\//d;
        $Value =~ s/\'/\\\'/g;
        $FORM{$Key} = $Value;
}

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");
unless ($COOKIE->{NO_ADS}) {
	require "/usr/local/git/fpa/cgi/display_adverts.ph";
	&display_adverts();
}


$Sts = $dbh->do("update invoices set invdesc='$FORM{newdescr}' where acct_id='$COOKIE->{ACCT}' and id=$FORM{id}");

print<<EOD;
Content-Type:text/plain

OK-
EOD
$dbh->disconnect;
exit;
