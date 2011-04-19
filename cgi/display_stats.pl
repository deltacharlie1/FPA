#!/usr/bin/perl

#  Script to display the stats graph

use GD;

@Data = split(/\:/,$ENV{QUERY_STRING});

$Max = 0;
$TotSales = 0;
$TotPurchases = 0;

foreach $Indx ( 1..12 ) {
	@Line = split(/\|/,$Data[$Indx]);
	if ($Max < $Line[1]) { $Max = $Line[1]; }
	$TotSales += $Line[1];
	if ($Max < $Line[2]) { $Max = $Line[2]; }
	$TotPurchases += $Line[2];
}

$Max = int($Max);

$Places = length($Max) - 2;
$Factor = 1;
if ($Places > 0) {
	$Factor .= substr('00000000000000000',0,$Places);
}

$Max = $Factor * 100;

$Curmonth = `date +%m`;
chomp($Curmonth);

$Curmonth++;
if ($Curmonth > 12) { $Curmonth = 1; }

$image = GD::Image->new(350,165);
# $lightgrey = $image->colorAllocate(240,240,240);
$white = $image->colorAllocate(255,255,255);
$black = $image->colorAllocate(0,0,0);
$red = $image->colorAllocate(255,0,0);
$blue = $image->colorAllocate(0,0,255);
$darkgreen = $image->colorAllocate(0,127,0);
$lightgreen = $image->colorAllocate(0,255,0);

#  Draw the x & y axes

$image->line(56,24,56,123,$black);
$image->line(56,123,344,123,$black);

#  y-axis gradations

$Charpos = 54 - ((length($Max) - 1)*8);
$image->line(54,24,56,24,$black);
$image->string(gdMediumBoldFont,$Charpos - 8,20,$Max,$black);
$image->line(54,49,56,49,$black);
$image->string(gdMediumBoldFont,$Charpos,42,int(($Max / 4) * 3),$black);
$image->line(54,74,56,74,$black);
$image->string(gdMediumBoldFont,$Charpos,67,int($Max / 2),$black);
$image->line(54,99,56,99,$black);
$image->string(gdMediumBoldFont,$Charpos,92,int($Max / 4),$black);

$Mth = $Curmonth;

for ($i=0; $i<12; $i++) {
	$posn = ($i*24)+56;
	if ($i > 0) {
		$image->line($posn,123,$posn,125,$black);
	}
	($Month,$Sales,$Purchases) = split(/\|/,$Data[$Mth]);

	$image->char(gdMediumBoldFont,$posn+9,123,$Month,$black);			#  month
	if ($Sales > 0) {
		$Sales = int($Sales / $Factor);
		$image->filledRectangle($posn+1,122,$posn+10,122-$Sales,$blue);		#  Sales
	}
	if ($Purchases > 0) {
		$Purchases = int($Purchases / $Factor);
		$image->filledRectangle($posn+11,122,$posn+20,122-$Purchases,$red);	#  Purchases
	}
	$Mth++;
	if ($Mth > 12) { $Mth = 1; }
}

if ($Data[0] =~ /Inv/i) {

#  Display the key

	$image->string(gdLargeFont,130,0,"Sales & Purchases",$black);
	$image->line(344,24,344,123,$black);
	$image->filledRectangle(60,140,70,150,$blue);
	$image->string(gdSmallFont,75,140,"Sales",$black);
	$image->filledRectangle(120,140,130,150,$red);
	$image->string(gdSmallFont,135,140,"Cost of Sales",$black);
	$image->line(220,145,230,145,$darkgreen);
	$image->string(gdSmallFont,235,140,"Annualised RoS",$black);

#  Calculate the annual Return on SAles

	$RoS = int((($TotSales - $TotPurchases) / $TotSales) * 100);
	$image->line(56,123 - $RoS,344,123 - $RoS,$darkgreen);

}
else {
	$image->string(gdLargeFont,135,0,"Receipts & Payments",$black);
	$image->filledRectangle(60,140,70,150,$blue);
	$image->string(gdSmallFont,75,140,"Receipts",$black);
	$image->filledRectangle(130,140,140,150,$red);
	$image->string(gdSmallFont,145,140,"Payments",$black);
}
print "Content-Type: image/png\n\n";
print $image->png;
exit;
