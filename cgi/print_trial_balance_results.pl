#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to update a VAT return

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

use CGI;
use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");

$Data = new CGI;
%FORM = $Data->Vars;

while (( $Key,$Value) = each %FORM) {

#  Remove any bad characters

	$Value =~ tr/\\//d;
	$Value =~ s/\'/\\\'/g;
        $FORM{$Key} = $Value;
}

#  List VAT entries in simple text format

#  Save the current filter settings

$Sts = $dbh->do("update tempstacks set f1='$FORM{tbselect}',f2='$FORM{tbstart}',f3='$FORM{tbend}' where acct_id='$COOKIE->{ACCT}' and caller='report'");

$Report_date = `date +%d-%b-%y`;
chomp($Report_date);

$Tot_debit = 0;
$Tot_credit = 0;

#  Set up the header

print<<EOD;
Content-Type: text/plain\n\n

<div id="print_listing" style="overflow:auto; width:600px;height:600px;padding-top:10px;background-color:#ffffff;color:#000000;font-weight:normal;">
<pre>
EOD

format STDOUT_TOP =
           Trial Balance Period:  @>>>>>>>>>>  to  @<<<<<<<<<<
$FORM{tbstart},$FORM{tbend}

Report Date: @<<<<<<<<<<                                       Page No: @<<<
$Report_date,$%

Date       Code  Detail                                        Debit     Credit
----------------------------------------------------------------------------------
.

format STDOUT = 
@<<<<<<<<  @<<<  @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<  @>>>>>>>>  @>>>>>>>>
$Nominal->{printdate},$Nominal->{ncode},$Detail->{cusname},$Debit,$Credit
.

$Invoices = $dbh->prepare("select concat(invcusname,' (',invdesc,')') as cusname from invoices where acct_id='$COOKIE->{ACCT}' and id=?");
$Txns = $dbh->prepare("select concat(txncusname,' (',txnremarks,')') as cusname from transactions where acct_id='$COOKIE->{ACCT}' and id=?");

$Nominals = $dbh->prepare("select nominals.id as nid,link_id,nomtype,nomcode as ncode,nomamount as amount,date_format(nomdate,'%d-%b-%y') as printdate,coatype from nominals left join coas on (nomcode=coanominalcode and nominals.acct_id=coas.acct_id) where nomdate>=str_to_date('$FORM{tbstart}','%d-%b-%y') and nomdate<=str_to_date('$FORM{tbend}','%d-%b-%y') and nominals.acct_id='$COOKIE->{ACCT}' order by nominals.nomdate,nominals.id");
$Nominals->execute;
while ($Nominal = $Nominals->fetchrow_hashref) {
	if ($Nominal->{coatype} =~ /Assets|Expenses/i) {
		if ($Nominal->{nomtype} =~ /T/i) {
			$Txns->execute($Nominal->{link_id});
			$Detail = $Txns->fetchrow_hashref;
		}
		else {
			$Invoices->execute($Nominal->{link_id});
			$Detail = $Invoices->fetchrow_hashref;
		}
		if ($Nominal->{amount} < 0) {
			$Credit = $Nominal->{amount};
			$Credit =~ tr/-//d;
			$Tot_credit += $Credit;
			$Debit = "";
		}
		else {
			$Debit = $Nominal->{amount};
			$Debit =~ tr/-//d;
			$Tot_debit += $Debit;
			$Credit = "";
		}
	}
	else {
		if ($Nominal->{nomtype} =~ /T/i) {
			$Txns->execute($Nominal->{link_id});
			$Detail = $Txns->fetchrow_hashref;
		}
		else {
			$Invoices->execute($Nominal->{link_id});
			$Detail = $Invoices->fetchrow_hashref;
		}
		if ($Nominal->{amount} >= 0) {
			$Credit = $Nominal->{amount};
			$Credit =~ tr/-//d;
			$Tot_credit += $Credit;
			$Debit = "";
		}
		else {
			$Debit = $Nominal->{amount};
			$Debit =~ tr/-//d;
			$Tot_debit += $Debit;
			$Credit = "";
		}
	}
	write;
}
print "--------------------------------------------------------------------------------\n";
printf "           Totals                                          %9.2f  %9.2f\n",$Tot_debit,$Tot_credit;
print "================================================================================\n</pre>\n</div>";

$Invoices->finish;
$Txns->finish;
$Nominals->finish;
$dbh->disconnect;
exit;
