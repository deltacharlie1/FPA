#!/usr/bin/perl

#  script to test template toolkit

$ACCESS_LEVEL = 1;

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

unlink "/projects/tmp/$COOKIE->{COOKIE}";

print<<EOD;
Content-Type: text/html
Status: 301
Location: /cgi-bin/fpa/login.pl

EOD
exit;
