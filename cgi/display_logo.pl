#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to update Company Details

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");
($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});

#  Get the image

$Companies = $dbh->prepare("select comlogo from companies where reg_id=$Reg_id and id=$Com_id");
$Companies->execute;
($Logo) = $Companies->fetchrow;
$Companies->finish;
$dbh->disconnect;

use MIME::Base64;
 $Logo = decode_base64($Logo);

print "Content-Type: image/jpg\n\n";
print $Logo;
exit;
