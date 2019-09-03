#!/usr/bin/perl

$dte = "21/01/19";
$dte =~ s/(\d\d)\/(\d\d)\/(\d\d)/20$3-$2-$1/;

print $dte."\n";
