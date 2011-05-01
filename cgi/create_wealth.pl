#!/usr/bin/perl

#  Script to produce the raw invoice and transaction stats

use DBI;

$dbh = DBI->connect("DBI:mysql:fpa");

@Month = ('X','J','F','M','A','M','J','J','A','S','O','N','D');

$Noms = $dbh->prepare("select sum(nomamount) as tot,date_format(nomdate,'%m') as printdate from nominals where acct_id=? and nomcode in ('1200','1210','1300','1310') group by printdate order by nomdate");

#$Companies = $dbh->prepare("select reg_id,id from companies");
#$Companies->execute;
#while ($Company = $Companies->fetchrow_hashref) {

#	$Acct_id = "$Company->{reg_id}+$Company->{id}";
	my $Acct_id="1+1";
	my @casData;
	my $Max = 0;
	my $Accum = 0;
	my $AccumMax = 0;
	my $AccumMin = 0;

#  First add the Month letter to the array

	foreach $Mth ( 1..12 ) {
		$casData[$Mth] = $Month[$Mth];
	}

########   INvoices   #######################

#  Get Current,Deposit,Cash & Cheques monthly totals

	$Noms->execute($Acct_id);
	$hNoms = $Noms->fetchall_arrayref({});
	foreach $Nom ( @$hNoms ) {
		$casData[$Nom->{printdate}] .= "|$Nom->{tot}";
	}

#  Now check to see if any months have been missed

	foreach my $Indx ( 1..12 ) {
		unless ($casData[$Indx] =~ /\|/) {
			$casData[$Indx] .= "|0";
		}
	}

#  write the datato the company record

	$casData = join(":",@casData);
#	$txnData = join(":",@txnData);

#	$Sts = $dbh->do("update companies set comrecstats='$casData',compaystats='$txnData' where reg_id=$Company->{reg_id} and id=$Company->{id}");
#}
$Noms->finish;
# $Companies->finish;
$dbh->disconnect;
# exit;

#  Script to display the stats graph

use GD;

@Data = @casData;

foreach $Line  (@Data) {
	@Cell = split(/\|/,$Line);
	$Accum += $Cell[1];
	if ($AccumMax < $Accum) { $AccumMax = $Accum; }
	if ($AccumMin > $Accum) { $AccumMin = $Accum; }
	$Cell[1] =~ tr/-//d;
	if ($Max < $Cell[1]) { $Max = $Cell[1]; }
}
if ($AccumMax < 0 - $AccumMin) { $AccumMax = $AccumMin; }

$Max = int($Max);
$AccumMax = int($AccumMax);

$Factor = $Max;
$Factor = substr($Max,0,1);
 
$Factor++;
$Factor .= substr('00000000000000000',0,length($Max)-1);
$Max = $Factor;

$Factor = int($Max / 50);

$AccumMax = int($AccumMax);
$AccumAccumMax = int($AccumAccumMax);

$MaxFactor = $AccumMax;
$MaxFactor = substr($AccumMax,0,1);
 
$MaxFactor++;
$MaxFactor .= substr('00000000000000000',0,length($AccumMax)-1);
$AccumMax = $MaxFactor;

$MaxFactor = int($AccumMax / 50);

$Curmonth = `date +%m`;
chomp($Curmonth);

$Curmonth++;
if ($Curmonth > 12) { $Curmonth = 1; }

$image = GD::Image->new(350,165);
 $lightgrey = $image->colorAllocate(240,240,240);
$white = $image->colorAllocate(255,255,255);
$black = $image->colorAllocate(0,0,0);
$red = $image->colorAllocate(255,0,0);
$darkred = $image->colorAllocate(127,0,0);
$blue = $image->colorAllocate(0,0,255);
$darkgreen = $image->colorAllocate(0,127,0);
$lightgreen = $image->colorAllocate(192,255,192);
$lightred = $image->colorAllocate(255,192,192);
#  Draw the x & y axes

$image->line(66,24,66,123,$black);
$image->line(66,74,282,74,$black);
$image->line(66,123,282,123,$black);
$image->line(282,24,282,123,$black);

#  y-axis gradations

$image->line(64,24,66,24,$black);
$image->string(gdMediumBoldFont,64 - (length($Max)*8),20,$Max,$black);
$image->line(64,49,66,49,$black);
$image->string(gdMediumBoldFont,64 - (length(int($Max / 2))*8),42,int($Max / 2),$black);
$image->line(64,74,66,74,$black);
$image->string(gdMediumBoldFont,42,67,"0",$black);
$image->line(64,99,66,99,$black);
$image->string(gdMediumBoldFont,56 - (length(int($Max / 2))*8),92,"-".int($Max / 2),$black);
# $image->line(54,123,56,123,$black);
$image->string(gdMediumBoldFont,56 - (length($Max)*8),116,"-".int($Max),$black);
$image->line(282,24,284,24,$black);
$image->string(gdMediumBoldFont,288,20,$AccumMax,$black);
$image->line(282,49,284,49,$black);
$image->string(gdMediumBoldFont,288,42,int($AccumMax / 2),$black);
$image->line(282,99,284,99,$black);
$image->string(gdMediumBoldFont,288,92,"-".int($AccumMax / 2),$black);
# $image->line(54,123,56,123,$black);
$image->string(gdMediumBoldFont,288,116,"-".int($AccumMax),$black);

#  First plot the accumulated cash

$Mth = $Curmonth;
$Accum = 0;
$Accum2 = 0;
for ($i=0; $i<12; $i++) {
	$posn = ($i*18)+66;
	($Month,$Sales,$Purchases) = split(/\|/,$Data[$Mth]);
	$Accum2 += $Sales;
# warn "i = $i\t-\tposn = $posn\t-\ty1 = $y1\t-\ty2 = $y2\n";
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

#  Set up the x-axis scale (months)

$Mth = $Curmonth;
for ($i=0; $i<12; $i++) {
	$posn = ($i*18)+66;
	if ($i > 0) {
		$image->line($posn,123,$posn,125,$black);
	}
	($Month,$Sales,$Purchases) = split(/\|/,$Data[$Mth]);

	$image->char(gdMediumBoldFont,$posn+6,123,$Month,$black);			#  month
	if ($Sales > 0) {
		$Sales = int($Sales / $Factor);
		$image->filledRectangle($posn+4,74,$posn+14,74-$Sales,$blue);		#  Sales
	}
	if ($Sales < 0) {
		$Sales = int($Sales / $Factor);
		$image->filledRectangle($posn+4,74,$posn+14,74-$Sales,$red);	#  Purchases
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

#  Calculate the annual Return on SAles

#$RoS = int((($TotSales - $TotPurchases) / $TotSales) * 100);
#$image->line(56,123 - $RoS,344,123 - $RoS,$darkgreen);

# print "Content-Type: image/png\n\n";
print $image->png;
exit;
