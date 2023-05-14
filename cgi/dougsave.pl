#!/usr/bin/perl

use CGI;
use CGI::Carp qw ( fatalsToBrowser );
use File::Basename;

$CGI::POST_MAX = 1024 * 10000;
my $safe_filename_characters = "a-zA-Z0-9_.-";
my $upload_dir = "/tmp";
my $Response = "";

my $query = new CGI;
@Params = $query->param;
#open(FILE, ">>/tmp/dougstl.txt");
foreach $filename (@Params) {
$Param = $query->param($filename);
	$Response .= "<b>Doug - $Param</b>\n";
#	print FILE "$Param\n";
}
#close(FILE);
print "Content-Type: test/plain\n\n$Response";
exit;



my $filename = $query->param("file");
my $email_address = $query->param("email_address");

if ( !$filename )
{
print $query->header ( );
print "There was a problem uploading your photo (try a smaller file).";
exit;
}

my ( $name, $path, $extension ) = fileparse ( $filename, '..*' );
$filename = $name . $extension;
$filename =~ tr/ /_/;
$filename =~ s/[^$safe_filename_characters]//g;

if ( $filename =~ /^([$safe_filename_characters]+)$/ )
{
$filename = $1;
}
else
{
die "Filename contains invalid characters";
}

my $upload_filehandle = $query->upload("photo");

open ( UPLOADFILE, ">$upload_dir/$filename" ) or die "$!";
binmode UPLOADFILE;

while ( <$upload_filehandle> )
{
print UPLOADFILE;
}

close UPLOADFILE;

print $query->header ( );
print <<END_HTML;
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<title>Thanks!</title>
<style type="text/css">
img {border: none;}
</style>
</head>
<body>
<p>Thanks for uploading your photo!</p>
<p>Your email address: $email_address</p>
<p>Your photo:</p>
<p><img src="/upload/$filename" alt="Photo" /></p>
</body>
</html>
END_HTML

