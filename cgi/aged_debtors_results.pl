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

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");
#  Save the current filter settings

$Sts = $dbh->do("update tempstacks set f1='$FORM{tbselect}',f2='$FORM{tbstart}',f3='$FORM{tbend}' where acct_id='$COOKIE->{ACCT}' and caller='report'");

#  Processing is as follows:L-
#
#  1.  Run through all sales & refund invoices with print date within the date range, sorted by invoice within customer
#  2.  For each invoice select all inv_txns
#  3.  Accumulate total paid (net+vat) of inv_txns with paid date <= end date range
#  4.  Subtract accumulated total from total invoice value
#  5.  If remainder > 0 accumulate total to appropriate customer aged debtor column

$Invoices = $dbh->prepare("select id as invid,invcusname,invtotal+invvat as amtdue,date_format(invprintdate,'%d-%b-%y') as printdate,concat('Invoice ',invinvoiceno,' (',invdesc,')') as descr,datediff(str_to_date('$FORM{tbend}','%d-%b-%y'),invprintdate) as overdue,'0' as amtpaid,'0' as amtoverdue from invoices where acct_id='$COOKIE->{ACCT}' and invprintdate>=str_to_date('$FORM{tbstart}','%d-%b-%y') and invprintdate <=str_to_date('$FORM{tbend}','%d-%b-%y') and invstatuscode>'1' and invtype='S' order by invcusname,invinvoiceno");
$Invoices->execute;
$Invoice = $Invoices->fetchall_arrayref({});

# foreach $i (0..@{$Invoice} - 1) {

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
# warn "$Invoice->[$i]->{invcusname} - $Invoice->[$i]->{amtdue} - $Invoice->[$i]->{amtpaid} - $Invoice->[$i]->{amtoverdue}\n";
		$i++;
	}
}

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
});

$Vars = {
	 ads => $Adverts,
	cookie => $COOKIE,
	tbstart => $FORM{tbstart},
	tbend => $FORM{tbend},
	suppress => $FORM{suppress},
	numrows => $Invoices->rows,
	curcus => "",
	colheader => "Debtor",
        entries => $Invoice
};

print "Content-Type: text/html\n\n";
$tt->process('aged_debtors_results.tt',$Vars);

$Inv_txns->finish;
$Invoices->finish;
$dbh->disconnect;
exit;

