#!/usr/bin/perl

use GD;

#  Total measured height = 156 pixels

#  Get the values used to calculate the image

my ($Remaining,$Max) = split(/\?/,$ENV{QUERY_STRING});

$Remaining =~ tr/0-9\.//cd;
$Max =~ tr/0-9\.//cd;

#  Make sure we don't have any empty fields

$Remaining = $Remaining || 0;
$Max =  $Max || 0;
my $Min = 0;

#  Calculate the display capacity remaining

if ($Remaining > 999999) {	#  ie we are in the megabytes
	$Disp_remaining = sprintf("(%01.1fMb)",$Remaining / 1000000);
}
elsif ($Remaining > 999) {
	$Disp_remaining = sprintf("(%01.1fKb)",$Remaining / 1000);
}
else {
	$Disp_remaining = "($Remaining)";
}

$Disp_max = int($Max / 1000000);

my $image;

$image = GD::Image->new(502,52);

#  Set the colours used

my $white = $image->colorAllocate(255,255,255);
my $blue = $image->colorAllocate(0,0,127);
my $red = $image->colorAllocate(215,128,128);
my $black = $image->colorAllocate(0,0,0);
my $grey = $image->colorAllocate(128,128,128);

$image->string(gdMediumBoldFont,100,0,"Remaining Upload Capacity $Disp_remaining",$black);
$image->string(gdMediumBoldFont,25,15,"0Mb",$black);
$image->string(gdMediumBoldFont,405,15,"${Disp_max}Mb",$black);
$image->rectangle(50,15,400,30,$grey);

#  Now calculate the posn of what is left

if ($Max > 0) {
	$Posn = 51 + (int(($Remaining / $Max) * 100) * 3.5);
	$image->line($Posn,15,$Posn,30,$red);
	$image->fill(51,20,$red);
}



print "Content-Type: image/png\n\n";
print $image->png;
exit;
