#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  Save new nominal codes

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

use CGI;
use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");

$Data = new CGI;
%FORM = $Data->Vars;

while (( $Key,$Value) = each %FORM) {

#  Remove any bad characters

	$Value =~ s/\%2b/\+/ig;
	$Value =~ tr/\\//d;
	$Value =~ s/\'/\\\'/g;
        $DATA{$Key} = $Value;
}

($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});

$DATA{data} =~ tr/\r\n//d;
$DATA{data} =~ s/<(?!\/).+?>//g;
$DATA{data} =~ s/<\/tr>/\n/ig;
$DATA{data} =~ s/<\/td>/\t/ig;

#  Get the account ids

$Accts = $dbh->prepare("select id,acctype from accounts where acct_id='$COOKIE->{ACCT}'");
$Accts->execute;
$Acct = $Accts->fetchall_hashref('acctype');
$Accts->finish;

$Earnings = 0;

#  Get the next transaction no

$Companies = $dbh->prepare("select comnexttxn from companies where reg_id=$Reg_id and id=$Com_id");
$Companies->execute;
@Company = $Companies->fetchrow;

@Nomcodes = split(/\n/,$DATA{data});
foreach $Nomcode (@Nomcodes) {
        @bCell = split(/\t/,$Nomcode);

#  Update the COA

	$Sts = $dbh->do("update coas set coabalance=coabalance + '$bCell[2]' where acct_id='$COOKIE->{ACCT}' and coanominalcode='$bCell[0]'");

	if ($bCell[0] < 2000) {		#  Asset so add to Retained Earnings
		$Earnings += $bCell[2];

#  create a transaction record

		$Sts = $dbh->do("insert into transactions (acct_id,txncusname,txnmethod,txnamount,txndate,txntxntype,txnremarks,txntxnno,txnselected) values ('$COOKIE->{ACCT}','Opening Balance','$bCell[0]','$bCell[2]',str_to_date('$DATA{obdate}','%d-%b-%y'),'income','$bCell[1]','$Company[0]','F')");
		$New_txn_id = $dbh->last_insert_id(undef, undef, qw(transactions undef));
		$Company[0]++;

#  Add 2 nominal records

		$Sts = $dbh->do("insert into nominals (acct_id,link_id,nomtype,nomcode,nomamount,nomdate) values ('$COOKIE->{ACCT}',$New_txn_id,'T','$bCell[0]','$bCell[2]',str_to_date('$DATA{obdate}','%d-%b-%y'))");
		$Sts = $dbh->do("insert into nominals (acct_id,link_id,nomtype,nomcode,nomamount,nomdate) values ('$COOKIE->{ACCT}',$New_txn_id,'T','3100','$bCell[2]',str_to_date('$DATA{obdate}','%d-%b-%y'))");

#  If this is 1200 or 1210 add an initial bank statment

		if ($bCell[0] =~ /1200/) {
			$Sts = $dbh->do("insert into statements (acct_id,acc_id,staclosebal,stastmtno,staclosedate,stanotxns,starec_no) values ('$COOKIE->{ACCT}',$Acct->{1200}->{id},'$bCell[2]','Opening Balance',str_to_date('$DATA{obdate}','%d-%b-%y'),'-1',0)");
		}
		if ($bCell[0] =~ /1210/) {
			$Sts = $dbh->do("insert into statements (acct_id,acc_id,staclosebal,stastmtno,staclosedate,stanotxns,starec_no) values ('$COOKIE->{ACCT}',$Acct->{1210}->{id},'$bCell[2]','Opening Balance',str_to_date('$DATA{obdate}','%d-%b-%y'),'-1',0)");
		}
	}
	else {
		$Earnings -= $bCell[2];

#  create a transaction record

		$Sts = $dbh->do("insert into transactions (acct_id,txncusname,txnmethod,txnamount,txndate,txntxntype,txnremarks,txntxnno,txnselected) values ('$COOKIE->{ACCT}','Opening Balance','$bCell[0]',0-'$bCell[2]',str_to_date('$DATA{obdate}','%d-%b-%y'),'income','$bCell[1]','$Company[0]','F')");
		$New_txn_id = $dbh->last_insert_id(undef, undef, qw(transactions undef));
		$Company[0]++;

#  Add 2 nominal records

		$Sts = $dbh->do("insert into nominals (acct_id,link_id,nomtype,nomcode,nomamount,nomdate) values ('$COOKIE->{ACCT}',$New_txn_id,'T','$bCell[0]','$bCell[2]',str_to_date('$DATA{obdate}','%d-%b-%y'))");
		$Sts = $dbh->do("insert into nominals (acct_id,link_id,nomtype,nomcode,nomamount,nomdate) values ('$COOKIE->{ACCT}',$New_txn_id,'T','3100',0-'$bCell[2]',str_to_date('$DATA{obdate}','%d-%b-%y'))");

	}
}

#  Update the Retained Earnings COA

$Sts = $dbh->do("update coas set coabalance=coabalance + '$Earnings' where acct_id='$COOKIE->{ACCT}' and coanominalcode='3100'");

#  Update the next transaction no

$Sts = $dbh->do("update companies set comnexttxn=comnexttxn+$Company[0] where reg_id=$Reg_id and id=$Com_id");

#  Add an audit trail comment

$Sts = $dbh->do("insert into audit_trails (acct_id,audtype,audaction,audtext,auduser) values ('$COOKIE->{ACCT}','opening balances','setup','Retained Earnings adjusted by &pound;$iEarnings for `Retained Earnings`','$COOKIE->{USER}')");

$Companies->finish;
$dbh->disconnect;
print<<EOD;
Content-Type: text/plain
Status: 301
Location: /cgi-bin/fpa/trial_balance.pl

EOD
exit;
