#!/usr/bin/perl

#  Script to change an errorneously entered date

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
$Sts = $dbh->do("update coas set coadesc='$FORM{newdescr}' where acct_id='$COOKIE->{ACCT}' and id=$FORM{id}");

$Sts = $dbh->do("insert into audit_trails (acct_id,link_id,audtype,audaction,audtext,auduser) values ('$COOKIE->{ACCT}',$FORM{id},'','change','COA Description changed to $FORM{newdescr}','$COOKIE->{USER}')");

print<<EOD;
Content-Type:text/plain

OK-
EOD
$dbh->disconnect;
exit;
