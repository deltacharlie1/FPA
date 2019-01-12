#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to upload a document or image using jquery uploadify

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});

use CGI;
use MIME::Base64;

$Data = new CGI;
%FORM = $Data->Vars;

while (( $Key,$Value) = each %FORM) {

#  Remove any bad characters

	$Value =~ tr/\\//d;
	$Value =~ s/\'/\\\'/g;
        $FORM{$Key} = $Value;
}

#  Get the uploaded raw data

$handle = $Data->upload("file");

$Original = "";
while (<$handle>) {
        $Original .= $_;
}

#  Get the ACCT from the cookie file (cookie is passed as a parameter)

open(COOKIE,"/projects/tmp/$FORM{cookie}");
while (<COOKIE>) {
	chomp($_);
	($Name,$Value) = split(/\t/,$_);
	$COOKIE->{$Name} = $Value;
	$Cookie{$Name} = $Value;
}
close(COOKIE);

($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");

#use Image::Magick;
#$Img = Image::Magick->new;

#  Convert image to an Image Magick object

#$status = $Img->BlobToImage($Original);
#($width,$height) = $Img->Get('width','height');	#  Get the dimensions


#if ($FORM{doc_type} =~ /LOGO/i) {
##	if ($width > 280 || $height > 95) {
#		if ($width > $height * 3) {
#			$W1 = 280;
#			$H1 = int(280 * $height / $width);
#		}
#		else {
#			$H1 = 95;
#			$W1 = int(95 * $width / $height);
#		}
#		$Img->Resize(width=>$W1,height=>$H1,blur=>'0');
#	}
#	$Logo = $Img->ImageToBlob(magick=>'jpg');

#	$Logo = encode_base64($Logo);

$Logo = encode_base64($Original);

#  ... and save it

$Companies = $dbh->prepare("update companies set comlogo=? where reg_id=$Reg_id and id=$Com_id");
$Companies->bind_param(1,$Logo);
$Companies->execute;

print "1";

$dbh->disconnect;
exit;
