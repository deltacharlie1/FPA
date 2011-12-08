#!/usr/bin/perl

#  script to test template toolkit

$ACCESS_LEVEL = 0;

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

use DBI;

$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");
$Acct_id = $COOKIE->{ACCT};

@Month = ('X','J','F','M','A','M','J','J','A','S','O','N','D');

$Sales = $dbh->prepare("select sum(invtotal) as tot,date_format(invprintdate,'%m') as printdate from invoices where invtype in ('S','C') and invstatuscode > 1 and acct_id=? and invprintdate > date_sub(now(),interval 1 year) group by printdate order by invprintdate");
$Purchases = $dbh->prepare("select sum(invtotal) as tot,date_format(invprintdate,'%m') as printdate from invoices where invtype in ('P','R') and invstatuscode > 1 and acct_id=? and invprintdate > date_sub(now(),interval 1 year) group by printdate order by invprintdate");
$Txnsin = $dbh->prepare("select sum(txnamount) as tot,date_format(txndate,'%m') as printdate from transactions where txntxntype in ('income','bankint') and txncusname<>'Opening Balance' and acct_id=? and txndate > date_sub(now(),interval 1 year) group by printdate order by txndate");
$Txnsout = $dbh->prepare("select sum(txnamount) as tot,date_format(txndate,'%m') as printdate from transactions where txntxntype in ('expense','bankexp') and txncusname<>'Opening Balance' and acct_id=? and txndate > date_sub(now(),interval 1 year) group by printdate order by txndate");
$Noms1 = $dbh->prepare("select sum(nomamount) as tot from nominals where acct_id=? and nomcode in ('1200','1210','1300','1310') and nomdate <= date_sub(now(),interval 1 year)");
$Noms2 = $dbh->prepare("select sum(nomamount) as tot,date_format(nomdate,'%m') as printdate from nominals where acct_id=? and nomcode in ('1200','1210','1300','1310') and nomdate > date_sub(now(),interval 1 year) group by printdate order by nomdate");

$Sales_found = "";
$Txns_found = "";
$Cash_found = "";

$Acct_id = $COOKIE->{ACCT};
my @invData;
my @txnData;
my @netData;

#  First add the Month letter to the array

foreach $Mth ( 1..12 ) {
	$invData[$Mth] = $Month[$Mth];
	$txnData[$Mth] = $Month[$Mth];
	$netData[$Mth] = $Month[$Mth];
}

########   INvoices   #######################

#  Get Sales figures

$Sales->execute($Acct_id);
$hSales = $Sales->fetchall_arrayref({});
foreach $Sale ( @$hSales ) {
	$invData[$Sale->{printdate}] .= "|$Sale->{tot}";
	if ($Sale->{tot} > 0) {
		$Sales_found = "1";
	}
}

#  Now check to see if any months have been missed

foreach my $Indx ( 1..12 ) {
	unless ($invData[$Indx] =~ /\|/) {
		$invData[$Indx] .= "|0";
	}
}

#  Get Purchases

$Purchases->execute($Acct_id);
$hPurchases = $Purchases->fetchall_arrayref({});
foreach $Purchase ( @$hPurchases ) {
	$Purchase->{tot} = 0-$Purchase->{tot};
	$invData[$Purchase->{printdate}] .= "|$Purchase->{tot}";
	if ($Purchase->{tot} > 0) {
		$Sales_found = "1";
	}
}

#  Now check to see if any months have been missed

foreach $Indx ( 1..12 ) {
	unless ($invData[$Indx] =~ /\|.+\|/) {
		$invData[$Indx] .= "|0";
	}
}

############   Transactions   ###################

#  Get Sales figures

$Txnsin->execute($Acct_id);
$hTxnsin = $Txnsin->fetchall_arrayref({});
foreach $Txnin ( @$hTxnsin ) {
	$txnData[$Txnin->{printdate}] .= "|$Txnin->{tot}";
	if ($Txnin->{tot} > 0) {
		$Txns_found = "1";
	}
}

#  Now check to see if any months have been missed

foreach $Indx ( 1..12 ) {
	unless ($txnData[$Indx] =~ /\|/) {
		$txnData[$Indx] .= "|0";
	}
}

#  Get Purchases

$Txnsout->execute($Acct_id);
$hTxnsout = $Txnsout->fetchall_arrayref({});
foreach $Txnout ( @$hTxnsout ) {
	$Txnout->{tot} = 0-$Txnout->{tot};
	$txnData[$Txnout->{printdate}] .= "|$Txnout->{tot}";
	if ($Txnout->{tot} > 0) {
		$Txns_found = "1";
	}
}

#  Now check to see if any months have been missed

foreach $Indx ( 1..12 ) {
	unless ($txnData[$Indx] =~ /\|.+\|/) {
		$txnData[$Indx] .= "|0";
	}
}

#############   Cash Flow   ###################

$Noms1->execute($Acct_id);
$Nom1 = $Noms1->fetchrow_hashref;		#  Get the net total up to 1 year ago

$Noms2->execute($Acct_id);
$hNoms = $Noms2->fetchall_arrayref({});
foreach $Nom ( @$hNoms ) {
	$netData[$Nom->{printdate}] .= "|$Nom->{tot}";
	if ($Nom->{tot} > 0) {
		$Cash_found = "1";
	}
}
foreach $Indx ( 1..12 ) {
	unless ($netData[$Indx] =~ /\|/) {
		$netData[$Indx] .= "|0";
	}
}

#  write the datato the company record

if ($Sales_found) { $invData = join(":",@invData); }
if ($Txns_found) { $txnData = join(":",@txnData); }
if ($Cash_found) { $netData = join(":",@netData); }

($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});

$Sts = $dbh->do("update companies set cominvstats='$invData',comtxnstats='$txnData',comnetstats='$netData' where reg_id=$Reg_id and id=$Com_id");

undef @invData;
undef @txnData;
undef @netData;
$invData = "";
$txnData = "";
$netData = "";

$Noms1->finish;
$dbh->disconnect;

unlink "/projects/tmp/$COOKIE->{COOKIE}";

print<<EOD;
Content-Type: text/html
Status: 301
Location: /cgi-bin/fpa/login.pl

EOD
exit;
