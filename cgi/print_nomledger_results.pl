#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to list nominal ledger for a data range

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

$Buffer = $ENV{QUERY_STRING};

@pairs = split(/&/,$Buffer);

# print "Content-Type: text/plain\n\n";

foreach $pair (@pairs) {

        ($Name, $Value) = split(/=/, $pair);

        $Value =~ tr/+/ /;
        $Value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C",hex($1))/eg;
        $Value =~ tr/\\\'//d;
        $FORM{$Name} = $Value;
}

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");

$Coas = $dbh->prepare("select nominals.nomcode,nominals.nomtype,nominals.link_id,coadesc,coatype,nominals.nomamount as balance,date_format(nominals.nomdate,'%d-%b-%y') as printdate,concat(txncusname,' (',txnremarks,')') as txndescr,concat(invcusname,' (',invdesc,')') as invdescr from nominals left join coas on (nominals.nomcode=coas.coanominalcode and nominals.acct_id=coas.acct_id) left join transactions on (nominals.link_id=transactions.id and nominals.acct_id=transactions.acct_id) left join invoices on (nominals.link_id=invoices.id and nominals.acct_id=invoices.acct_id) where str_to_date('$FORM{tbstart}','%d-%b-%y')<=nominals.nomdate and str_to_date('$FORM{tbend}','%d-%b-%y')>=nominals.nomdate and nominals.acct_id='$COOKIE->{ACCT}' order by nominals.nomcode,nominals.nomdate");
$Coas->execute;
$Coa = $Coas->fetchall_arrayref({});

$Curcode = $Coa->[0]->{nomcode};
$Curdesc = $Coa->[0]->{coadesc};

#  List VAT entries in simple text format

$Report_date = `date +%d-%b-%y`;
chomp($Report_date);

#  Set up the header

print<<EOD;
Content-Type: text/plain\n\n

<div style="overflow:auto; width:670px;height:600px;padding-top:10px;background-color:#ffffff;color:#000000;font-weight:normal;">
<pre id="print_listing">
EOD

format STDOUT_TOP =
@<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<   Nominal Ledger Period:  @>>>>>>>> to @<<<<<<<<
$COOKIE->{TAG},$FORM{tbstart},$FORM{tbend}

Report Date: @<<<<<<<<<<                                                                                      Page No: @<<<
$Report_date,$%

Code  Account            Date       Item Description                                                             Debit      Credit
------------------------------------------------------------------------------------------------------------------------------------
.

format STDOUT =
@<<<  @<<<<<<<<<<<<<<<<  @<<<<<<<<  @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<  @>>>>>>>>>  @>>>>>>>>>
$Coaitem->{nomcode},$Coaitem->{coadesc},$Coaitem->{printdate},$Coadescr,$Debit,$Credit
.

format SUMMARY = 
                                                                                                            ----------------------
                                                                                                Sub Total   @>>>>>>>>>  @>>>>>>>>>
$Tot_debits,$Tot_credits
                                                                                                            ----------------------
                                                                       @>>>>>>>>>>>>>>>>>>>>>>> Net Total   @>>>>>>>>>  @>>>>>>>>>
$Curdesc,$Net_debits,$Net_credits
                                                                                                            ======================

.

foreach $Coaitem (@$Coa) {

	if ($Coaitem->{nomcode} !~ /$Curcode/i) {
		if ($Tot_debits + $Tot_credits >= 0) {
			$Net_debits = sprintf('%1.2f',$Tot_debits + $Tot_credits);
			$Net_credits = "";
		}
		else {
			$Net_credits = sprintf('%1.2f',$Tot_debits + $Tot_credits);
			$Net_credits =~ tr/-//d;
			$Net_debits = "";
		}

		$Tot_debits =~ tr/-//d;
		$Tot_credits =~ tr/-//d;

		if ($Tot_debits > 0) { $Tot_debits = sprintf('%1.2f',$Tot_debits); }
		if ($Tot_credits > 0) { $Tot_credits = sprintf('%1.2f',$Tot_credits); }

		write SUMMARY;

		$Tot_debits = "";
		$Tot_credits = "";

		$Curcode = $Coaitem->{nomcode};
		$Curdesc = $Coaitem->{coadesc};
	}

	if ($Coaitem->{nomtype} =~ /T/i) {
		$Coadescr = $Coaitem->{txndescr};
	}
	else {
		$Coadescr = $Coaitem->{invdescr};
	}

	if ($Coaitem->{coatype} =~ /Assets|Expenses/i) {
		if ($Coaitem->{balance} >= 0) {
			$Debit = $Coaitem->{balance};
			$Credit = "";
		}
		else {
			$Credit = $Coaitem->{balance};
			$Debit = "";
		}
	}
	else {
		if ($Coaitem->{balance} >= 0) {
			$Credit = $Coaitem->{balance};
			$Debit = "";
		}
		else {
			$Debit = $Coaitem->{balance};
			$Credit = "";
		}
	}
	$Tot_debits += $Debit;
	$Tot_credits += $Credit;

	$Debit =~ tr/-//d;
	$Credit =~ tr/-//d;

	write;
}
write SUMMARY;
$Coadescr = "";
$Debit = "";
$Credit = "";
write;
print "</pre></div>\n";

$Coas->finish;
$dbh->disconnect;
exit;

