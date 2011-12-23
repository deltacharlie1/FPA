#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to do the actual cleardown of P & L accounts

#  All we actually need to do is to adjust each relevant coa entry and then, for each one, make a single entry in the nominals table plus one in 'retained earnings' (3100) for the total


use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");
unless ($COOKIE->{NO_ADS}) {
	require "/usr/local/git/fpa/cgi/display_adverts.ph";
	&display_adverts();
}


#  Calculate the year start and year end of the previous FY

($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});

$Dates = $dbh->prepare("select date_add(date_sub(comyearend,interval 1 year),interval 1 day) as fystart,date_sub(comyearend,interval 1 year) as tbend,date_sub(date_add(comyearend, interval 1 day), interval 2 year) as tbstart,date_format(date_sub(comyearend,interval 1 year),'%d-%b-%y') as dispend,date_format(date_sub(date_add(comyearend, interval 1 day), interval 2 year),'%d-%b-%y') as dispstart,comnexttxn from companies where reg_id=$Reg_id and id=$Com_id");
$Dates->execute;
$Date = $Dates->fetchrow_hashref;
$Dates->finish;

$Coas = $dbh->prepare("select coas.coanominalcode as nominalcode,coadesc,coatype,sum(nominals.nomamount) as balance from coas left join nominals on (nominals.nomcode=coas.coanominalcode and nominals.acct_id=coas.acct_id) where nominals.nomdate>='$Date->{tbstart}' and nominals.nomdate<='$Date->{tbend}' and coanominalcode>'3999' and coas.acct_id='$COOKIE->{ACCT}' group by nominals.nomcode order by nominals.nomcode");
$Coas->execute;
$Coa = $Coas->fetchall_arrayref({});

$Balance = 0;
$Txn_no = $Date->{comnexttxn};

foreach $Coaitem (@$Coa) {

	if ($Coaitem->{coatype} =~ /expense/i) {
		$Balance += $Coaitem->{balance};
	}
	else {
		$Balance -= $Coaitem->{balance};
	}

#  Make minus entry for amount in nominals

	$Sts = $dbh->do("insert into transactions (acct_id,txncusname,txnmethod,txnamount,txndate,txntxntype,txnremarks,txntxnno) values ('$COOKIE->{ACCT}','$Coaitem->{coadesc}','$Coaitem->{nominalcode}','$Coaitem->{balance}','$Date->{fystart}','yearend','Year End adjst','$Txn_no')");
	$New_txn_id = $dbh->last_insert_id(undef, undef, qw(transactions undef));
	$Txn_no++;

	$Sts = $dbh->do("insert into nominals (acct_id,link_id,nomamount,nomdate,nomcode) values ('$COOKIE->{ACCT}',$New_txn_id,0-'$Coaitem->{balance}','$Date->{fystart}','$Coaitem->{nominalcode}')");

	$Sts = $dbh->do("update coas set coabalance=coabalance-'$Coaitem->{balance}' where acct_id='$COOKIE->{ACCT}' and coanominalcode='$Coaitem->{nominalcode}'");
}

#  Now update Retained Earnings

$Sts = $dbh->do("insert into transactions (acct_id,txncusname,txnmethod,txnamount,txndate,txntxntype,txnremarks,txntxnno) values ('$COOKIE->{ACCT}','Retained Earnings','3100','$Balance','$Date->{fystart}','yearend','Year End adjst','$Txn_no')");
$New_txn_id = $dbh->last_insert_id(undef, undef, qw(transactions undef));
$Txn_no++;

$Sts = $dbh->do("insert into nominals (acct_id,link_id,nomamount,nomdate,nomcode) values ('$COOKIE->{ACCT}',$New_txn_id,0-'$Balance','$Date->{fystart}','3100')");

$Sts = $dbh->do("update coas set coabalance=coabalance+'$Balance' where acct_id='$COOKIE->{ACCT}' and coanominalcode='3100'");

#  Remove the reminder

$Sts = $dbh->do("delete from reminders where acct_id='$COOKIE->{ACCT}' and remcode='YRN'");

#  finally write an audit trail comment

$Balance = 0 - $Balance;
$Balance = sprintf('%1.2f',$Balance);

$Sts = $dbh->do("insert into audit_trails (acct_id,link_id,audtype,audaction,audtext,auduser) values ('$COOKIE->{ACCT}',$New_txn_id,'transactions','yearend','Transferred &pound;$Balance to Retained Earnings','$COOKIE->{USER}')");

print<<EOD;
Content-Type: text/html
Status: 301
Location: /cgi-bin/fpa/list_coas.pl

EOD

$Coas->finish;
$dbh->disconnect;
exit;

