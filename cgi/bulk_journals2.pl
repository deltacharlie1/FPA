#!/usr/bin/perl

$ACCESS_LEVEL = 3;

#  Processing =
#
#    ADD	to DEBIT account	=	DEBIT
#    SUBRACT	from DEBIT Account	=	CREDIUT
#
#    ADD	to CREDIT Account	=	CREDIT
#    SUBTRACT	from CREDIT Account	=	DEBIT
#

#  Save new invoices for a bookkeeper's client

#  Column order is:-

#  0 - Date
#  1 - Description
#  2 - Account
#  3 - Debit
#  4 - Credit

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

use CGI;
use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");
chomp($Curdate);

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

#  Get the next journal no

$Companies = $dbh->prepare("select comnexttxn,comnextjnl from companies where reg_id=$Reg_id and id=$Com_id");
$Companies->execute;
$Company = $Companies->fetchrow_hashref;
$Companies->finish;

$Nexttxn = $Company->{comnexttxn};
$Nextjnlno = $Company->{comnextjnl};

#  Get existing coas

$Coa_types = $dbh->prepare("select distinct coanominalcode,coatype,coareport from coas where acct_id='$COOKIE->{ACCT}'");
$Coa_types->execute;
$Coa_type = $Coa_types->fetchall_hashref('coanominalcode');
$Coa_types->finish;

$DATA{data} =~ s/\&nbsp;//g;
$DATA{data} =~ s/<(?!\/).+?>//g;
$DATA{data} =~ s/<\/tr>/\n/ig;
$DATA{data} =~ s/<\/td>/\t/ig;

#  0 - Date, 1 - Description, 2 - Account,  3 - Debit, 4 - Credit

$New_jnl_id = 0;

@Journals = split(/\n/,$DATA{data});
foreach $Journal (@Journals) {
        @bCell = split(/\t/,$Journal);
	$Ndx = 0;

#  if we have a date then it is a new journal

	if ($bCell[0]) {

#  First see if we need to update an open journal

		if ($New_jnl_id) {
			$Sts = $dbh->do("update journals set jouacct='$Main_acct',joutype='$Jnltype',jouamt='$Jnlamt',joucount=$Jnlcount where acct_id='$COOKIE->{ACCT}' and id=$New_jnl_id");
		}
		$New_jnl_id = 0;
		$Main_acct = '';
		$Jnltype = '';
		$Jnlamt = '0';
		$Jnlcount = 0;

#  Create a new journal entry

		$Sts = $dbh->do("insert into journals (acct_id,joudate,joudesc,joujnlno) values ('$COOKIE->{ACCT}',str_to_date('$bCell[0]','%d-%b-%y'),'$bCell[1]','$Nextjnlno')");
		$New_jnl_id = $dbh->last_insert_id(undef, undef, qw(journals undef));

		$Jnl_date = $bCell[0];
		$Jnl_desc = $bCell[1];
		$Jnl_no = $Nextjnlno;

		$Nextjnlno++;

#  Add an audit trail entry

		$Sts = $dbh->do("insert into audit_trails (acct_id,link_id,audtype,audaction,audtext,auduser) values ('$COOKIE->{ACCT}',$New_jnl_id,'update_invoice.pl','journal','$Jnl_desc (JE - $Jnl_no)','$COOKIE->{USER}')");

	}

	$Jnlcount++;

#  Get the account code

	if ($bCell[3] > $Jnlamt) {
		$Jnlamt = $bCell[3];
		$Main_acct = $bCell[2];
		$Jnltype = 'Debit';
	}
	elsif ($bCell[4] > $Jnlamt) {
		$Jnlamt = $bCell[3];
		$Main_acct = $bCell[2];
		$Jnltype = 'Credit';
	}
	
	$bCell[2] = substr($bCell[2],0,4);

#  Sort out signs

#  Determine the Type of the Acct:-

#  Type A = Assets & Expenses
#  		Debit reduces
#  		Credit increases
#
#  Type B = Liabilities, Capital, Sales
#  		Debit increases
#  		Credit reduces

	$Txnamount = $bCell[3] || $bCell[4];

	if ($Coa_type->{$bCell[2]}->{coatype} =~ /Asset|Expense/i || $bCell[2] == 3050) {					#  Debit
		$Txntype = "expense";
		$Vatcode = "6000";
		if ($bCell[4]) {
			$Txnamount = 0 - $Txnamount;
		}
	}
	else {					#  Credit
		$Txntype = "income";
		$Vatcode = "4300";
		if ($bCell[3]) {
			$Txnamount = 0 - $Txnamount;
		}
	}

#  Add a transaction record if this is a 1200-1300 account

	if ($bCell[2] >= 1200 && $bCell[2] <= 1300) {

		$Sts = $dbh->do("insert into transactions (acct_id,link_id,txncusname,txnmethod,txnamount,txndate,txntxntype,txnremarks,txnyearend,txntxnno) values ('$COOKIE->{ACCT}',$New_jnl_id,'Journal','$bCell[2]','$Txnamount',str_to_date('$Jnl_date','%d-%b-%y'),'$Txntype','$Jnl_desc (JE - $Jnl_no)','$COOKIE->{YEAREND}','$Nexttxn')");
		$New_txn_id = $dbh->last_insert_id(undef, undef, qw(transactions undef));
		$Nexttxn++;
	}

#  Add a vataccrual if this is a VAT entry

	if ($bCell[2] =~ /1400/ || $bCell[2] =~ /2100/) {

		$Sts = $dbh->do("update companies set comvatcontrol=comvatcontrol - '$Txnamount' where reg_id=$Reg_id and id=$Com_id");

		$Sts = $dbh->do("insert into vataccruals (acct_id,acrtype,acrvat,acrprintdate,acrnominalcode,acrtxn_id) values ('$COOKIE->{ACCT}','J','0'-'$Txnamount',str_to_date('$Jnl_date','%d-%b-%y'),'$Vatcode',$New_jnl_id)");
	}

#  Finally add the nominal entry and update coas

	if ($New_txn_id) {
		$Sts = $dbh->do("insert into nominals (acct_id,link_id,nomtype,nomcode,nomamount,nomdate,journal_id) values ('$COOKIE->{ACCT}',$New_txn_id,'T','$bCell[2]','$Txnamount',str_to_date('$Jnl_date','%d-%b-%y'),$New_jnl_id)");
		$Sts = $dbh->do("update coas set coabalance=coabalance + '$Txnamount' where coanominalcode='$bCell[2]' and acct_id='$COOKIE->{ACCT}'");
	}
	else {
		$Sts = $dbh->do("insert into nominals (acct_id,link_id,nomtype,nomcode,nomamount,nomdate,journal_id) values ('$COOKIE->{ACCT}','$New_jnl_id','J','$bCell[2]','$Txnamount',str_to_date('$Jnl_date','%d-%b-%y'),$New_jnl_id)");
		$Sts = $dbh->do("update coas set coabalance=coabalance + '$Txnamount' where coanominalcode='$bCell[2]' and acct_id='$COOKIE->{ACCT}'");
	}
	$New_txn_id = '';

}
if ($New_jnl_id) {
	$Sts = $dbh->do("update journals set jouacct='$Main_acct',joutype='$Jnltype',jouamt='$Jnlamt',joucount=$Jnlcount where acct_id='$COOKIE->{ACCT}' and id=$New_jnl_id");
}

#  finally update the next txn and next jnl nos in companies

$Sts = $dbh->do("update companies set comnexttxn='$Nexttxn',comnextjnl='$Nextjnlno' where reg_id=$Reg_id and id=$Com_id");

$dbh->disconnect;
print<<EOD;
Content-Type: text/plain
Status: 302
Location: /cgi-bin/fpa/jnlrep1.pl

EOD
exit;
