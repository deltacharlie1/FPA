#!/usr/bin/perl

#  Script to update txnselected of a particular transaction

$ACCESS_LEVEL = 1;

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

@pairs = split(/&/,$ENV{QUERY_STRING});

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
unless ($COOKIE->{NO_ADS}) {
	require "/usr/local/git/fpa/cgi/display_adverts.ph";
	&display_adverts();
}


$FORM{txnid} =~ s/^x//;

$Sts = $dbh->do("update transactions set txnselected='$FORM{state}' where acct_id='$COOKIE->{ACCT}' and id=$FORM{txnid}");

$dbh->disconnect;
exit;
