#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to list VAT entries by VAT Return

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

$Accruals = $dbh->prepare("select if(vatreturns.id,vatreturns.id,'aaa') as col1,perquarter,perbox3,perbox4,acrvat,date_format(acrprintdate,'%d-%b-%y') as printdate, concat(invcusname,'(',invinvoiceno,' - ',invdesc,')') as acrdesc,acrtype,acrvat as acramt,inv_txns.inv_id as inv_id from vataccruals left join inv_txns on (acrtxn_id=inv_txns.id and vataccruals.acct_id=inv_txns.acct_id) left join invoices on (inv_txns.inv_id=invoices.id and inv_txns.acct_id=invoices.acct_id) left join vatreturns on (vr_id=vatreturns.id and vataccruals.acct_id=vatreturns.acct_id) where vataccruals.acct_id='$COOKIE->{ACCT}' and str_to_date('$FORM{tbstart}','%d-%b-%y')<= perstartdate and str_to_date('$FORM{tbend}','%d-%b-%y')>=perenddate  and acrvat <> 0 order by col1,acrprintdate");
$Accruals->execute;
$Accrual = $Accruals->fetchall_arrayref({});

#  List VAT entries in simple text format

$Report_date = `date +%d-%b-%y`;
chomp($Report_date);

print<<EOD;
Content-type: text/plain
Content-Disposition: attachment; filename=vatlist.csv

EOD

print "\"VAT Return\",\"Date\",\"Item Description\",\"VAT Input\",\"VAT Output\"\n";
foreach $item (@$Accrual) {
	$Vatinp = '';
	$Vatoutp = '';

	if ($item->{acrvat} >= 0) {
		$Vatinp = sprintf("%1.2f",$item->{acrvat});
	}
	else {
		$Vatoutp = sprintf("%1.2f",(0-$item->{acrvat}));
	}
	print "\"$item->{perquarter}\",\"$item->{printdate}\",\"$item->{acrdesc}\",$Vatinp,$Vatoutp\n";
}
$Accruals->finish;
$dbh->disconnect;
exit;

