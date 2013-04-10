#!/usr/bin/perl

use DBI;
$dbh = DBI->connect("DBI:mysql:fpa");
$Companies = $dbh->prepare("select comname,companies.reg_id,id,regemail from companies left join registrations using (reg_id) where comvatscheme like '%F%'");
$Companies->execute;
while ($Company = $Companies->fetchrow_hashref) {
	$Acct_id = "$Company->{reg_id}+$Company->{id}";
	$Invoices = $dbh->prepare("select id,invinvoiceno,invtotal,invvat,invtype,date_format(invprintdate,'%d-%b-%y') as printdate from invoices where acct_id='$Acct_id' and invtype in ('P','R') and invvat <> '0.00' and (invtotal+invvat)<=2000");
	$Invoices->execute;
	if ($Invoices->rows > 0) {

		print "\n$Acct_id - $Company->{comname} - $Company->{regemail}\n===========================================================\n";

		while ($Invoice = $Invoices->fetchrow_hashref) {
			print "$Invoice->{id}, $Invoice->{invinvoiceno}, $Invoice->{invtotal}, $Invoice->{invvat}, $Invoice->{invtype}, $Invoice->{printdate}\n";

			$Gross = $Invoice->{invtotal} + $Invoice->{invvat};
			$Gross = 0 - $Gross;
			$dbh->do("update nominals set nomamount='$Gross' where link_id=$Invoice->{id} and (nomcode >= '4000' or nomcode<'1100')");
			$dbh->do("delete from nominals where link_id=$Invoice->{id} and nomcode='1400'");
			$Nominals = $dbh->prepare("select * from nominals where link_id=$Invoice->{id} and (nomcode >= '4000' or nomcode<'1100')");
			$Nominals->execute;
			while (@Nominal = $Nominals->fetchrow) {
				print "@Nominal\n";
			}
		}
	}
}
$Nominals->finish;
$Invoices->finish;
$Companies->finish;
$dbh->disconnect;
exit;

