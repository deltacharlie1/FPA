#!/usr/bin/perl

#  Script to produce the raw invoice and transaction stats

use DBI;

$dbh = DBI->connect("DBI:mysql:fpa");

@Month = ('X','J','F','M','A','M','J','J','A','S','O','N','D');

$Sales = $dbh->prepare("select sum(invtotal) as tot,date_format(invprintdate,'%m') as printdate from invoices where invtype in ('S','C') and invstatuscode > 1 and acct_id=? and invprintdate > date_sub(now(),interval 1 year) group by printdate order by invprintdate");
$Purchases = $dbh->prepare("select sum(invtotal) as tot,date_format(invprintdate,'%m') as printdate from invoices where invtype in ('P','R') and invstatuscode > 1 and acct_id=? and invprintdate > date_sub(now(),interval 1 year) group by printdate order by invprintdate");
$Txnsin = $dbh->prepare("select sum(txnamount) as tot,date_format(txndate,'%m') as printdate from transactions where txntxntype in ('income','bankint') and txncusname<>'Opening Balance' and acct_id=? and txndate > date_sub(now(),interval 1 year) group by printdate order by txndate");
$Txnsout = $dbh->prepare("select sum(txnamount) as tot,date_format(txndate,'%m') as printdate from transactions where txntxntype in ('expense','bankexp') and txncusname<>'Opening Balance' and acct_id=? and txndate > date_sub(now(),interval 1 year) group by printdate order by txndate");
$Noms1 = $dbh->prepare("select sum(nomamount) as tot from nominals where acct_id=? and nomcode in ('1200','1210','1300','1310') and nomdate <= date_sub(now(),interval 1 year)");
$Noms2 = $dbh->prepare("select sum(nomamount) as tot,date_format(nomdate,'%m') as printdate from nominals where acct_id=? and nomcode in ('1200','1210','1300','1310') and nomdate > date_sub(now(),interval 1 year) group by printdate order by nomdate");

$Companies = $dbh->prepare("select reg_id,id from companies");
$Companies->execute;
while ($Company = $Companies->fetchrow_hashref) {

	$Acct_id = "$Company->{reg_id}+$Company->{id}";
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
	}
	foreach $Indx ( 1..12 ) {
		unless ($netData[$Indx] =~ /\|/) {
			$netData[$Indx] .= "|0";
		}
	}

#  write the datato the company record
	$invData = join(":",@invData);
	$txnData = join(":",@txnData);
	$netData = join(":",@netData);

print "$Acct_id\t$invData\n\t$txnData\n\t$netData\n\n";

	$Sts = $dbh->do("update companies set cominvstats='$invData',comtxnstats='$txnData',comnetstats='$netData' where reg_id=$Company->{reg_id} and id=$Company->{id}");
}
$Noms1->finish;
$Companies->finish;
$dbh->disconnect;
exit;
