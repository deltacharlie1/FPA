#!/usr/bin/perl

#$ACCESS_LEVEL = 0;

#  script to process registration update details

#use Checkid;
#$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

#($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});

print "Content-Type: text/plain\n\nOK";

read(STDIN, $Buffer, $ENV{'CONTENT_LENGTH'});

warn "subs_validate = ".$Buffer."\n\n";

@pairs = split(/&/,$Buffer);

foreach $pair (@pairs) {

        ($Name, $Value) = split(/=/, $pair);

        $Value =~ tr/+/ /;
        $Value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C",hex($1))/eg;
        $Value =~ tr/\\//d;             #  Remove all back slashes
        $Value =~ s/(\'|\")/\\$1/g;
        $FORM{$Name} = $Value;
warn "$Key = $Value\n";
}
exit;

