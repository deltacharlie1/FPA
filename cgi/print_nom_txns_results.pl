#!/usr/bin/perl

warn "Testing\n";

$ACCESS_LEVEL = 1;

#  script to list invoices

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
# print "$Name = $Value\n";
}
# exit;

$SQL = "";
if ($FORM{txnremarks}) {
	$SQL .= "transactions.txnremarks like '$FORM{txnremarks}%' and ";
}
if ($FORM{invtype}) {
	$SQL .= "transactions.txntxntype='$FORM{invtype}' and ";
}
if ($FORM{tbstart}) {
        $SQL .= "txndate >= str_to_date('$FORM{tbstart}','%d-%b-%y') and ";
}
if ($FORM{tbend}) {
        $SQL .= "txndate <= str_to_date('$FORM{tbend}','%d-%b-%y') and ";
}
$SQL .= "transactions.acct_id='$COOKIE->{ACCT}'";

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");

#  Save the current filter settings

$Sts = $dbh->do("update tempstacks set f1='$FORM{tbselect}',f2='$FORM{tbstart}',f3='$FORM{tbend}' where acct_id='$COOKIE->{ACCT}' and caller='report'");

warn "\$Txns = \$dbh->prepare(\"select transactions.id,txntxnno,txnamount,date_format(txndate,'%d-%b-%y') as printdate,txnmethod,txncusname,txnremarks,inv_id,sum(itnet) as net,sum(itvat) as vat from transactions left join inv_txns on (transactions.id=inv_txns.txn_id and transactions.acct_id=inv_txns.acct_id) where $SQL group by transactions.id order by txndate ,txntxnno\")\n";
$Txns = $dbh->prepare("select transactions.id,txntxnno,txnamount,date_format(txndate,'%d-%b-%y') as printdate,txnmethod,txncusname,txnremarks,inv_id,sum(itnet) as net,sum(itvat) as vat from transactions left join inv_txns on (transactions.id=inv_txns.txn_id and transactions.acct_id=inv_txns.acct_id) where $SQL group by transactions.id order by txndate ,txntxnno");
$Txns->execute;

$Txn = $Txns->fetchall_arrayref({});

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
@<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<    Nominal Ledger Period:  @>>>>>>>> to @<<<<<<<<
$COOKIE->{TAG},$FORM{tbstart},$FORM{tbend}

Report Date: @<<<<<<<<<<                                                                                      Page No: @<<<
$Report_date,$%
                                                                                                            Paid Out                 Paid In
Date        Txn #      Account   Customer                        Description                            Net         VAT          Net         VAT
----------------------------------------------------------------------------------------------------------------------------------------------------
.

format STDOUT =
@<<<<<<<<   @<<<<<<<<  @<<<<<<   @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<  @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<  @>>>>>>>>>  @>>>>>>>>>  @>>>>>>>>>>  @>>>>>>>>>
$Invitem->{printdate},$Invitem->{txntxnno},$Invitem->{txnmethod},$Invitem->{txncusname},$Invitem->{txnremarks},$Outnet,$OutVAT,$Innet,$InVAT
.

foreach $Invitem (@$Txn) {
#	$Invitem->{txnremarks} = substr($Invitem->{txnremarks},0,25);
	if ($Invitem->{net} < 0) {
		$Invitem->{net} =~ tr/-//d;
		$Invitem->{vat} =~ tr/-//d;
		$Outnet = sprintf('%1.2f',$Invitem->{net});
		$OutVAT = sprintf('%1.2f',$Invitem->{vat});
		$Innet = '';
		$InVAT = '';
	}
	else {
		$Innet = sprintf('%1.2f',$Invitem->{net});
		$InVAT = sprintf('%1.2f',$Invitem->{vat});
		$Outnet = '';
		$OutVAT = '';
	}
	write;
}
print "</pre></div>\n";

$Invoices->finish;
$dbh->disconnect;
exit;

