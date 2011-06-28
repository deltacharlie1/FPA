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
# print "$Name = $Value\n";
}
# exit;

#$COOKIE->{DB} = "fpa";
#$COOKIE->{ACCT} = "1+1";
#$FORM{tbstart} = "01-Jul-10";
#$FORM{tbend} = "28-Jun-11";

use DBI;
my $dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");

#  Save the current filter settings

$Sts = $dbh->do("update tempstacks set f1='$FORM{tbselect}',f2='$FORM{tbstart}',f3='$FORM{tbend}' where acct_id='$COOKIE->{ACCT}' and caller='report'");

$Invoices = $dbh->prepare("select invoices.id as invid,invcusname,invtotal+invvat as amtdue,datediff(str_to_date('$FORM{tbend}','%d-%b-%y'),invprintdate) as overdue,sum(itnet+itvat) as amtpaid,invtotal+invvat-sum(itnet+itvat) as amtoverdue from invoices left join inv_txns on (invoices.id=inv_txns.inv_id and invoices.acct_id=inv_txns.acct_id) where invprintdate<=str_to_date('$FORM{tbend}','%d-%b-%y') and invstatuscode>'1' and invtype in ('S','R') and invoices.acct_id='$COOKIE->{ACCT}' group by invoices.id having amtpaid<amtdue or isnull(amtpaid)");
$Invoices->execute;

while (@Invoice = $Invoices->fetchrow) {

#  Get the current aged debotr totals

	($L1,$L2,$L3,$L4,$L5) = split(/\,/,$Debtor{"$Invoice[1]"});

	if ($Invoice[3] > 120) {
		$L5 += $Invoice[5] || $Invoice[2];
	}
	elsif ($Invoice[3] > 90) {
		$L4 += $Invoice[5] || $Invoice[2]
	}
	elsif ($Invoice[3] > 60) {
		$L3 += $Invoice[5] || $Invoice[2]
	}
	elsif ($Invoice[3] > 30) {
		$L2 += $Invoice[5] || $Invoice[2]
	}
	else {
		$L1 += $Invoice[5] || $Invoice[2]
	}

	$Debtor{"$Invoice[1]"} = "$L1,$L2,$L3,$L4,$L5";

}

#  In theory we should now have all debtors in a hash array

	foreach $key (sort keys %Debtor) {
		@Amt = split(/\,/,$Debtor{$key});
		push (@Debtors, { cusname => "$key", l1 => "$Amt[0]", l2 => "$Amt[1]", l3 => "$Amt[2]", l4 => "$Amt[3]", l5 => "$Amt[4]" });
	}

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
});

$No_entries = @Debtors;

$Vars = {
	cookie => $COOKIE,
	tbstart => $FORM{tbstart},
	tbend => $FORM{tbend},
	numrows => $No_entries,
        entries => \@Debtors
};

print "Content-Type: text/html\n\n";
$tt->process('aged_debtors_results.tt',$Vars);

$Coas->finish;
$dbh->disconnect;
exit;

