#!/usr/bin/perl

#  Script to get the environment variables

print "Content-Type: text/plain\n\n";
while (($Key,$Value) = each %ENV) {
	print "$Key = $Value\n";
}
exit;
