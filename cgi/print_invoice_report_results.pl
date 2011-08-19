#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to list nominal ledger for a data range

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

$Buffer = $ENV{QUERY_STRING};

@pairs = split(/&/,$Buffer);

foreach $pair (@pairs) {

        ($Name, $Value) = split(/=/, $pair);

        $Value =~ tr/+/ /;
        $Value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C",hex($1))/eg;
        $Value =~ tr/\\\'//d;
        $FORM{$Name} = $Value;
}

#$COOKIE->{DB} = "fpa";
#$COOKIE->{ACCT} = "1+1";
#$FORM{tbstart} = "01-Jul-10";
#$FORM{tbend} = "30-Jun-11";

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");
unless ($COOKIE->{NO_ADS}) {
	require "/usr/local/git/fpa/cgi/display_adverts.ph";
	&display_adverts();
}


$Accruals = $dbh->prepare("select if(vatreturns.id,vatreturns.id,'aaa') as col1,perquarter,perbox3,perbox4,acrvat,date_format(acrprintdate,'%d-%b-%y') as printdate, concat(invcusname,'(',invinvoiceno,' - ',invdesc,')') as acrdesc,acrtype,acrvat as acramt,inv_txns.inv_id as inv_id from vataccruals left join inv_txns on (acrtxn_id=inv_txns.id and vataccruals.acct_id=inv_txns.acct_id) left join invoices on (inv_txns.inv_id=invoices.id and inv_txns.acct_id=invoices.acct_id) left join vatreturns on (vr_id=vatreturns.id and vataccruals.acct_id=vatreturns.acct_id) where vataccruals.acct_id='$COOKIE->{ACCT}' and str_to_date('$FORM{tbstart}','%d-%b-%y')<=acrprintdate and str_to_date('$FORM{tbend}','%d-%b-%y')>=acrprintdate order by col1,acrprintdate");
$Accruals->execute;
$Accrual = $Accruals->fetchall_arrayref({});

$Curcode = $Accrual->[0]->{perquarter};

#  List VAT entries in simple text format

$Report_date = `date +%d-%b-%y`;
chomp($Report_date);

#  Set up the header

print<<EOD;
Content-Type: text/plain\n\n

<div id="print_listing" style="overflow:auto; width:670px;height:600px;padding-top:10px;background-color:#ffffff;color:#000000;font-weight:normal;">
<pre>
EOD

format STDOUT_TOP =
                                          VAT Reconciliation Report Period:  @>>>>>>>> to @<<<<<<<<
$FORM{tbstart},$FORM{tbend}

Report Date: @<<<<<<<<<<                                                                                      Page No: @<<<
$Report_date,$%

Return  Date       Item Description                                                                  VAT Input   VAT Output  
-----------------------------------------------------------------------------------------------------------------------------
.

format STDOUT =
@<<<<   @<<<<<<<<  @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<  @>>>>>>>>>  @>>>>>>>>>
$Accitem->{perquarter},$Accitem->{printdate},$Accitem->{acrdesc},$Debit,$Credit
.

format SUMMARY = 
                                                                                         ------------------------------------
                                                                                         Sub Total   @>>>>>>>>>  @>>>>>>>>>
$Tot_debits,$Tot_credits
                                                                                         ====================================
.

foreach $Accitem (@$Accrual) {

	if ($Accitem->{perquarter} !~ /$Curcode/i) {

		$Tot_debits =~ tr/-//d;
		$Tot_credits =~ tr/-//d;

		if ($Tot_debits > 0) { $Tot_debits = sprintf('%1.2f',$Tot_debits); }
		if ($Tot_credits > 0) { $Tot_credits = sprintf('%1.2f',$Tot_credits); }

		write SUMMARY;

		$Tot_debits = "";
		$Tot_credits = "";

		$Curcode = $Accitem->{perquarter};
	}

	if ($Accitem->{acrvat} >= 0) {
		$Debit = $Accitem->{acrvat};
		$Credit = "";
	}
	else {
		$Credit = $Accitem->{acrvat};
		$Debit = "";
	}

	$Tot_debits += $Debit;
	$Tot_credits += $Credit;

	$Debit =~ tr/-//d;
	$Credit =~ tr/-//d;

	write;
}

$Tot_debits =~ tr/-//d;
$Tot_credits =~ tr/-//d;

if ($Tot_debits > 0) { $Tot_debits = sprintf('%1.2f',$Tot_debits); }
if ($Tot_credits > 0) { $Tot_credits = sprintf('%1.2f',$Tot_credits); }

write SUMMARY;
$Debit = "";
$Credit = "";
write;
print "</pre></div>\n";

$Coas->finish;
$dbh->disconnect;
exit;

