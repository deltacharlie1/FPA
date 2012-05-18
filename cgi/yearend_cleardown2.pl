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

$Dates = $dbh->prepare("select date_add(date_sub(comyearend,interval 1 year),interval 1 day) as fystart,date_sub(comyearend,interval 1 year) as tbend,date_sub(date_add(comyearend, interval 1 day), interval 2 year) as tbstart,date_format(date_sub(comyearend,interval 1 year),'%d-%b-%y') as dispend,date_format(date_sub(date_add(comyearend, interval 1 day), interval 2 year),'%d-%b-%y') as dispstart,comnexttxn,comnextjnl from companies where reg_id=$Reg_id and id=$Com_id");
$Dates->execute;
$Date = $Dates->fetchrow_hashref;
$Dates->finish;
$Date->{tbstart} = '2011-07-01';
$Date->{tbend} = '2012-06-30';
$Date->{fystart} = '2012-07-01';
$Date->{dispstart} = '01-Jul-11';
$Date->{dispend} = '30-Jun-12';


$Coas = $dbh->prepare("select coas.coanominalcode as nominalcode,coadesc,coatype,sum(nominals.nomamount) as balance from coas left join nominals on (nominals.nomcode=coas.coanominalcode and nominals.acct_id=coas.acct_id) where nominals.nomdate>='$Date->{tbstart}' and nominals.nomdate<='$Date->{tbend}' and coanominalcode>'3999' and coas.acct_id='$COOKIE->{ACCT}' group by nominals.nomcode order by nominals.nomcode");
$Coas->execute;
$Coa = $Coas->fetchall_arrayref({});

#  Create a new journal entry for year end

$Sts = $dbh->do("insert into journals (acct_id,joudate,joudesc,joujnlno) values ('$COOKIE->{ACCT}','$Date->{tbend}','Year End entries for $Date->{dispend}','$Date->{comnextjnl}')");
$New_jnl_id = $dbh->last_insert_id(undef, undef, qw(journals undef));
$Date->{comnextjnl}++;

$Balance = 0;

$Jnl_count = 0;
foreach $Coaitem (@$Coa) {
	$Jnl_count++;
	if ($Coaitem->{coatype} =~ /expense/i) {
		$Balance += $Coaitem->{balance};
	}
	else {
		$Balance -= $Coaitem->{balance};
	}

#  Make minus entry for amount in nominals

	$Sts = $dbh->do("insert into nominals (acct_id,link_id,journal_id,nomamount,nomdate,nomcode,nomtype) values ('$COOKIE->{ACCT}',$New_jnl_id,$New_jnl_id,'0'-'$Coaitem->{balance}','$Date->{tbend}','$Coaitem->{nominalcode}','J')");

	$Sts = $dbh->do("update coas set coabalance=coabalance-'$Coaitem->{balance}' where acct_id='$COOKIE->{ACCT}' and coanominalcode='$Coaitem->{nominalcode}'");
}

#  Now update Retained Earnings

$Sts = $dbh->do("insert into nominals (acct_id,link_id,journal_id,nomamount,nomdate,nomcode,nomtype) values ('$COOKIE->{ACCT}',$New_jnl_id,$New_jnl_id,0-'$Balance','$Date->{tbend}','3100','J')");

$Sts = $dbh->do("update coas set coabalance=coabalance+'$Balance' where acct_id='$COOKIE->{ACCT}' and coanominalcode='3100'");

#  Update the journal entry

$Sts = $dbh->do("update journals set jouacct='3100 - Capital Account',joutype='Debit',jouamt='$Balance',joucount=$Jnl_count where acct_id='$COOKIE->{ACCT}' and id=$New_jnl_id");

#  Remove the reminder

$Sts = $dbh->do("delete from reminders where acct_id='$COOKIE->{ACCT}' and remcode='YRN'");

#  finally write an audit trail comment

$Balance = 0 - $Balance;
$Balance = sprintf('%1.2f',$Balance);

$Sts = $dbh->do("insert into audit_trails (acct_id,link_id,audtype,audaction,audtext,auduser) values ('$COOKIE->{ACCT}',$New_jnl_id,'transactions','journal','Transferred &pound;$Balance to Capital Account','$COOKIE->{USER}')");

#  Finally write back the next txn no

$Sts = $dbh->do("update companies set comnextjnl='$Date->{comnextjnl}' where reg_id=$Reg_id and id=$Com_id");

print<<EOD;
Content-Type: text/html
Status: 302
Location: /cgi-bin/fpa/jnlrep1.pl

EOD

$Coas->finish;
$dbh->disconnect;
exit;

