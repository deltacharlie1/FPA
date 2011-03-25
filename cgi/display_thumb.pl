#!/usr/bin/perl

use MIME::Base64;

$Thumb = decode_base64($ENV{QUERY_STRING});

print "Content-Type: image/png\n\n";
print $Thumb;
exit;
