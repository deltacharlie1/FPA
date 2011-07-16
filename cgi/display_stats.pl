#!/usr/bin/perl

#  Script to display the stats graph

use GD;

@Month = split(/\:/,$ENV{QUERY_STRING});

$Graphtype = $Month[0];

$Max = 0;
$AccumMax = 0;
$AccumMin = 0;

foreach $Indx ( 1..12 ) {
	@Cell = split(/\|/,$Month[$Indx]);
	if ($Graphtype =~ /Net/i) {
		$Accum += $Cell[1];
		if ($AccumMax < $Accum) { $AccumMax = $Accum; }
		if ($AccumMin > $Accum) { $AccumMin = $Accum; }
	}
	$Cell[1] =~ tr/-//d;
	if ($Max < $Cell[1]) { $Max = $Cell[1]; }
	$Cell[2] =~ tr/-//d;
	if ($Max < $Cell[2]) { $Max = $Cell[2]; }
}

$Max = int($Max);
$AccumMax = int($AccumMax);

$Factor = $Max;
$Factor = substr($Max,0,1);

$Factor++;
$Factor .= substr('00000000000000000',0,length($Max)-1);
$Max = $Factor;

if ($Graphtype =~ /Net/i) {
	$Factor = int($Max / 50);

	$AccumMax = int($AccumMax);
	$AccumAccumMax = int($AccumAccumMax);

	$MaxFactor = $AccumMax;
	$MaxFactor = substr($AccumMax,0,1);

	$MaxFactor++;
	$MaxFactor .= substr('00000000000000000',0,length($AccumMax)-1);
	$AccumMax = $MaxFactor;

	$MaxFactor = int($AccumMax / 50);
}
else {
	$Factor = int($Max / 100);
}


$Curmonth = `date +%m`;
chomp($Curmonth);

$Curmonth++;
if ($Curmonth > 12) { $Curmonth = 1; }

$image = GD::Image->new(350,165);
# $lightgrey = $image->colorAllocate(240,240,240);
$white = $image->colorAllocate(255,255,255);
$black = $image->colorAllocate(64,64,64);
$red = $image->colorAllocate(255,64,64);
$lightred = $image->colorAllocate(255,216,216);
$blue = $image->colorAllocate(64,64,255);
$darkgreen = $image->colorAllocate(0,127,0);
$lightgreen = $image->colorAllocate(216,255,216);

#  Draw the x & y axes

$image->line(66,24,66,123,$black);
if ($Graphtype =~ /Net/i) {
	$image->line(66,74,282,74,$black);
	$image->line(282,24,282,123,$black);
}
$image->line(66,123,282,123,$black);

#  y-axis gradations

if ($Graphtype =~ /Net/i) {

#  Above & Below type graph

	$image->line(64,24,66,24,$black);
	$image->string(gdMediumBoldFont,64 - (length($Max)*8),20,$Max,$black);
	$image->line(64,49,66,49,$black);
	$image->string(gdMediumBoldFont,64 - (length(int($Max / 2))*8),42,int($Max / 2),$black);
	$image->line(64,74,66,74,$black);
	$image->string(gdMediumBoldFont,42,67,"0",$black);
	$image->line(64,99,66,99,$black);
	$image->string(gdMediumBoldFont,56 - (length(int($Max / 2))*8),92,"-".int($Max / 2),$black);
	$image->string(gdMediumBoldFont,56 - (length($Max)*8),116,"-".int($Max),$black);
	$image->line(282,24,284,24,$black);
	$image->string(gdMediumBoldFont,288,20,$AccumMax,$black);
	$image->line(282,49,284,49,$black);
	$image->string(gdMediumBoldFont,288,42,int($AccumMax / 2),$black);
	$image->line(282,99,284,99,$black);
	$image->string(gdMediumBoldFont,288,92,"-".int($AccumMax / 2),$black);
	$image->string(gdMediumBoldFont,288,116,"-".int($AccumMax),$black);

	$Mth = $Curmonth;
	$Accum = 0;
	$Accum2 = 0;
	for ($i=0; $i<12; $i++) {
		$posn = ($i*18)+66;
		($Month,$Sales,$Purchases) = split(/\|/,$Month[$Mth]);
		$Accum2 += $Sales;
		unless ($Accum == 0 && $Accum2 == 0) {
			$y1 = int($Accum / $MaxFactor);
			$y2 = int($Accum2 / $MaxFactor);
			$image->line($posn,75-$y1,$posn+18,75-$y2,$darkgreen);
			if ($y1 < 0 && $y2 >= 1) {
				$image->fill($posn+1,76,$lightred);
			}
			elsif ($y1 >= 1 && $y2 < 0) {
				$image->fill($posn+1,73,$lightgreen);
			}
		}
		$Accum = $Accum2;
		$Mth++;
		if ($Mth > 12) { $Mth = 1; }
	}
	if ($Accum < 1) {
		$image->fill($posn+1,76,$lightred);
	}
	elsif ($Accum >= 1) {
		$image->fill($posn+1,73,$lightgreen);
	}

	$Mth = $Curmonth;
	for ($i=0; $i<12; $i++) {
		$posn = ($i*18)+66;
		if ($i > 0) {
			$image->line($posn,123,$posn,125,$black);
		}
		($Month,$Sales) = split(/\|/,$Month[$Mth]);

		$image->char(gdMediumBoldFont,$posn+6,123,$Month,$black);                       #  month
		if ($Sales > 0) {
			$Sales = int($Sales / $Factor);
			$image->filledRectangle($posn+4,74-$Sales,$posn+14,74,$blue);           #  Sales
		}
		if ($Sales < 0) {
			$Sales = int($Sales / $Factor);
			$image->filledRectangle($posn+4,74,$posn+14,74-$Sales,$red);    #  Purchases
		}
		$Mth++;
		if ($Mth > 12) { $Mth = 1; }
	}

#  Display the key

	$image->string(gdLargeFont,97,0,"Cashflow & Reserves",$black);
	$image->filledRectangle(60,140,70,150,$blue);
	$image->string(gdSmallFont,75,140,"Net In",$black);
	$image->filledRectangle(120,140,130,150,$red);
	$image->string(gdSmallFont,135,140,"Net Out",$black);
	$image->rectangle(190,140,200,150,$darkgreen);
	$image->fill(195,145,$lightgreen);
	$image->rectangle(200,140,210,150,$darkgreen);
	$image->fill(205,145,$lightred);
	$image->string(gdSmallFont,215,140,"Cash Reserves",$black);
}
else {

#  Above type only

	$image->line(64,24,66,24,$black);
	$image->string(gdMediumBoldFont,64 - (length($Max)*8),20,$Max,$black);
	$image->line(64,49,66,49,$black);
	$image->string(gdMediumBoldFont,64 - (length(int(($Max / 4) * 3))*8),42,int(($Max / 4) * 3),$black);
	$image->line(64,74,66,74,$black);
	$image->string(gdMediumBoldFont,64 - (length(int($Max / 2))*8),67,int($Max / 2),$black);
	$image->line(64,99,66,99,$black);
	$image->string(gdMediumBoldFont,64 - (length(int($Max / 4))*8),92,int($Max / 4),$black);

	$Mth = $Curmonth;

	for ($i=0; $i<12; $i++) {
		$posn = ($i*18)+66;
		if ($i > 0) {
			$image->line($posn,123,$posn,125,$black);
		}
		($Month,$Sales,$Purchases) = split(/\|/,$Month[$Mth]);

		$image->char(gdMediumBoldFont,$posn+6,123,$Month,$black);			#  month
		if ($Sales > 0) {
			$Sales = int($Sales / $Factor);
#			$image->filledRectangle($posn+2,122,$posn+9,122-$Sales,$blue);		#  Sales
			$image->filledRectangle($posn+2,122-$Sales,$posn+9,122,$blue);		#  Sales
		}
		if ($Purchases > 0) {
			$Purchases = int($Purchases / $Factor);
#			$image->filledRectangle($posn+10,122,$posn+16,122-$Purchases,$red);	#  Purchases
			$image->filledRectangle($posn+10,122-$Purchases,$posn+16,122,$red);	#  Purchases
		}
		$Mth++;
		if ($Mth > 12) { $Mth = 1; }
	}

	if ($Graphtype =~ /Inv/i) {

#  Display the key

		$image->string(gdLargeFont,138,0,"Invoices",$black);
		$image->filledRectangle(60,140,70,150,$blue);
		$image->string(gdSmallFont,75,140,"Sales",$black);
		$image->filledRectangle(120,140,130,150,$red);
		$image->string(gdSmallFont,135,140,"Purchase",$black);
#		$image->line(220,145,230,145,$darkgreen);
#		$image->string(gdSmallFont,235,140,"Annualised RoS",$black);

#  Calculate the annual Return on SAles

#		$RoS = int((($TotSales - $TotPurchases) / $TotSales) * 100);
#		$image->line(56,123 - $RoS,344,123 - $RoS,$darkgreen);

	}
	else {
		$image->string(gdLargeFont,135,0,"Transactions",$black);
		$image->filledRectangle(60,140,70,150,$blue);
		$image->string(gdSmallFont,75,140,"Receipts",$black);
		$image->filledRectangle(130,140,140,150,$red);
		$image->string(gdSmallFont,145,140,"Payments",$black);
	}
}
print "Content-Type: image/png\n\n";
print $image->png;
exit;
