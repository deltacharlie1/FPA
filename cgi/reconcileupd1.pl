#!/usr/bin/perl

#  Script to temporarily store reconciliation statement header stuff

$ACCESS_LEVEL = 1;

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

$Buffer = $ENV{QUERY_STRING};

@pairs = split(/&/,$Buffer);

foreach $pair (@pairs) {

        ($Name, $Value) = split(/=/, $pair);

        $Value =~ tr/+/ /;
        $Value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C",hex($1))/eg;
	$Value =~ tr/\\\'//d;
        $FORM{$Name} = $Value;
}

#  Script to test autosuggest

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");

$Sts = $dbh->do("update tempstacks set f1='$FORM{f1}',f2='$FORM{f2}',f3='$FORM{f3}',f4='$FORM{f4}',f5='$FORM{f5}',f6='$FORM{f6}' where acct_id='$COOKIE->{ACCT}' and caller='reconciliation'");

$dbh->disconnect;
exit;
