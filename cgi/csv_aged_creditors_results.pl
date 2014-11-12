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

#  List VAT entries in simple text format

$Invoices = $dbh->prepare("select id as invid,invcusname,invtotal+invvat as amtdue,date_format(invprintdate,'%d-%b-%y') as printdate,invinvoiceno,invdesc as descr,datediff(str_to_date('$FORM{tbend}','%d-%b-%y'),invprintdate) as overdue,'0' as amtpaid,'0' as amtoverdue from invoices where acct_id='$COOKIE->{ACCT}' and invprintdate>=str_to_date('$FORM{tbstart}','%d-%b-%y') and invprintdate <=str_to_date('$FORM{tbend}','%d-%b-%y') and invstatuscode>'1' and invtype='P' order by invcusname,invinvoiceno");
$Invoices->execute;
$Invoice = $Invoices->fetchall_arrayref({});

foreach $i (0..@{$Invoice} - 1) {
        $Inv_txns = $dbh->prepare("select sum(itnet+itvat) as amtpaid from inv_txns where acct_id='$COOKIE->{ACCT}' and itdate<=str_to_date('$FORM{tbend}','%d-%b-%y') and $Invoice->[$i]->{invid}=inv_id");
        $Inv_txns->execute;
        $Inv_txn = $Inv_txns->fetchrow_hashref;
        $Amtowed = $Invoice->[$i]->{amtdue} - $Inv_txn->{amtpaid};

        $Invoice->[$i]->{amtpaid} = $Inv_txn->{amtpaid};
        $Invoice->[$i]->{amtoverdue} = $Amtowed;
}

$i = 0;
while ($i < @{$Invoice}) {
        if ($Invoice->[$i]->{amtoverdue} == 0) {
                splice(@{$Invoice},$i,1);
        }
        else {
                $i++;
        }
}

$Report_date = `date +%d-%b-%y`;
chomp($Report_date);

print<<EOD;
Content-type: text/plain
Content-Disposition: attachment; filename=aged_creditors.csv

EOD

print "\"Creditor\",\"Invoice #\",\"Invoice Date\",\"Description\",\"Amount Overdue\",\"Days Overdue\"\n";
foreach $i  (0..@{$Invoice}) {
	print "\"$Invoice->[$i]->{invcusname}\",\"$Invoice->[$i]->{invinvoiceno}\",\"$Invoice->[$i]->{printdate}\",\"$Invoice->[$i]->{descr}\",\"$Invoice->[$i]->{amtoverdue}\",$Invoice->[$i]->{overdue}\n";
}
$Inv_txns->finish;
$Invoices->finish;
$dbh->disconnect;
exit;

