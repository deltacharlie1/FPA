#!/usr/bin/perl

$ACCESS_LEVEL = 3;

#  script to design an invoice layout

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");
unless ($COOKIE->{NO_ADS}) {
        require "/usr/local/git/fpa/cgi/display_adverts.ph";
        &display_adverts();
}

# $dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");

$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");

use Image::Magick;
$Img = Image::Magick->new;

#  Get the layut details

$Layouts = $dbh->prepare("select * from invoice_layouts where acct_id='$COOKIE->{ACCT}' and id=$ENV{QUERY_STRING}");
$Layouts->execute;
$Layout = $Layouts->fetchrow_hashref;
$Layouts->finish;

#  Convert image to an Image Magick object

$status = $Img->Read("$Layout->{layfile}");
@Image = $Img->ImageToBlob(magick=>'png');

print "Content-Type: image/png\n\n$Image[0]";

$dbh->disconnect;
exit;
