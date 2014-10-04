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

print<<EOD;
Content-type: text/plain
Content-Disposition: attachment; filename=fpaledger.csv

EOD

print "\"Code\",\"Account\",\"Date\",\"Item Description\",\"Debit\",\"Credit\"\n";
foreach $Coaitem (@$Coa) {

	if ($Coaitem->{nomtype} =~ /T/i) {
		$Coadescr = $Coaitem->{txndescr};
	}
	else {
		$Coadescr = $Coaitem->{invdescr};
	}
	$Coadescr =~ tr/\,/ \,/;
	if ($Coaitem->{coatype} =~ /Assets|Expenses/i) {
		if ($Coaitem->{balance} >= 0) {
			$Debit = $Coaitem->{balance};
			$Credit = "";
		}
		else {
			$Credit = 0 - $Coaitem->{balance};
			$Debit = "";
		}
	}
	else {
		if ($Coaitem->{balance} >= 0) {
			$Credit = 0 - $Coaitem->{balance};
			$Debit = "";
		}
		else {
			$Debit = $Coaitem->{balance};
			$Credit = "";
		}
	}
	print "\"$Coaitem->{nomcode}\",\"$Coaitem->{coadesc}\",\"$Coaitem->{printdate}\",\"$Coadescr\",$Debit,$Credit\n";
}
$Coas->finish;
$dbh->disconnect;
exit;

