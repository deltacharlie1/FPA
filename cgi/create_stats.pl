#!/usr/bin/perl

#  Script to produce the raw invoice and transaction stats

use DBI;

$dbh = DBI->connect("DBI:mysql:fpa");

@Month = ('X','J','F','M','A','M','J','J','A','S','O','N','D');

$Sales = $dbh->prepare("select sum(invtotal) as tot,date_format(invprintdate,'%m') as printdate from invoices where invtype in ('S','C') and invstatuscode > 1 and acct_id=? and invprintdate > date_sub(now(),interval 1 year) group by printdate order by invprintdate");
$Purchases = $dbh->prepare("select sum(invtotal) as tot,date_format(invprintdate,'%m') as printdate from invoices where invtype in ('P','R') and invstatuscode > 1 and acct_id=? and invprintdate > date_sub(now(),interval 1 year) group by printdate order by invprintdate");
$Txnsin = $dbh->prepare("select sum(txnamount) as tot,date_format(txndate,'%m') as printdate from transactions where txntxntype in ('income','bankint') and txncusname<>'Opening Balance' and acct_id=? and txndate > date_sub(now(),interval 1 year) group by printdate order by txndate");
$Txnsout = $dbh->prepare("select sum(txnamount) as tot,date_format(txndate,'%m') as printdate from transactions where txntxntype in ('expense','bankexp') and txncusname<>'Opening Balance' and acct_id=? and txndate > date_sub(now(),interval 1 year) group by printdate order by txndate");

$Companies = $dbh->prepare("select reg_id,id from companies");
$Companies->execute;
while ($Company = $Companies->fetchrow_hashref) {

	$Acct_id = "$Company->{reg_id}+$Company->{id}";
	my @invData;
	my @txnData;

#  First add the Month letter to the array

	foreach $Mth ( 1..12 ) {
		$invData[$Mth] = $Month[$Mth];
		$txnData[$Mth] = $Month[$Mth];
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

#  write the datato the company record
	$invData = join(":",@invData);
	$txnData = join(":",@txnData);

	$Sts = $dbh->do("update companies set comrecstats='$invData',compaystats='$txnData' where reg_id=$Company->{reg_id} and id=$Company->{id}");
}
$Companies->finish;
$dbh->disconnect;
exit;
