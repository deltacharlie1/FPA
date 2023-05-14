#!/usr/bin/perl

format STDOUT_TOP = 
Acct_id    User Name             Company Name          Mem Reg Date   Last Login No Days No Invoices
----------------------------------------------------------------------------------------------------
.

format STDOUT = 
@<<<<<<<<< @<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<<<<< @## @<<<<<<<<< @<<<<<<<<< @####   @####
$Acct_id, substr($Reg->{regusername},0,20), substr($Com->{comname},0,20), $Reg->{mem}, $Reg->{reg}, $Reg->{last}, $Reg->{diff}, $Invs
.

#  Script to delete old accounts (typically those with a reglastlogindate of greater than 2 years)

#  Set count

$Deleted_users = 0;

use DBI;
$dbh = DBI->connect("DBI:mysql:fpa3");

#  for each old registration

$Regs = $dbh->prepare("select regmembership as mem,reg_id,regusername,date_format(regregdate,'%d-%b-%y') as reg,date_format(reglastlogindate,'%d-%b-%y') as last,datediff(reglastlogindate,regregdate) as diff from registrations where reg_id!=3 and ((reglastlogindate < '2017-12-01' and regmembership<'2') or (datediff(reglastlogindate,regregdate)<1 and reglastlogindate<'2019-06-01')) order by reglastlogindate");
$Regs->execute;
while ($Reg = $Regs->fetchrow_hashref) {

	$Deleted_users++;

#    for each company with this reg_id

	$Coms = $dbh->prepare("select id,comname from companies where reg_id=$Reg->{reg_id}");
	$Coms->execute;
	while ($Com = $Coms->fetchrow_hashref) {

#      construct acct_id

		$Acct_id = "$Reg->{reg_id}+$Com->{id}";

#      delete accounts

		$Cnt = $dbh->do("delete from accounts where acct_id='$Acct_id'");
		$Cnt =~ s/0E0/0/;
#		print "\tAccounts - $Cnt\n";
#      delete audit_trails

		$Cnt = $dbh->do("delete from audit_trails where acct_id='$Acct_id'");
		$Cnt =~ s/0E0/0/;
#		print "\tAudit Trails - $Cnt\n";

#      delete coa_txns

		$Cnt = $dbh->do("delete from coa_txns where acct_id='$Acct_id'");
		$Cnt =~ s/0E0/0/;
#		print "\tCoa Txns - $Cnt\n";

#      delete coas

		$Cnt = $dbh->do("delete from coas where acct_id='$Acct_id'");
		$Cnt =~ s/0E0/0/;
#		print "\tCoas - $Cnt\n";

#      delete customers

		$Cnt = $dbh->do("delete from customers where acct_id='$Acct_id'");
		$Cnt =~ s/0E0/0/;
#		print "\tCustomers - $Cnt\n";

#      delete gcls

		$Cnt = $dbh->do("delete from gcls where acct_id='$Acct_id'");
		$Cnt =~ s/0E0/0/;
#		print "\tGcls - $Cnt\n";

#      delete images

		$Cnt = $dbh->do("delete from images where acct_id='$Acct_id'");
		$Cnt =~ s/0E0/0/;
#		print "\tImages - $Cnt\n";

#      delete inv_txns

		$Cnt = $dbh->do("delete from inv_txns where acct_id='$Acct_id'");
		$Cnt =~ s/0E0/0/;
#		print "\tInv Txns - $Cnt\n";

#      delete invoice_layout_items

		$Cnt = $dbh->do("delete from invoice_layout_items where acct_id='$Acct_id'");
		$Cnt =~ s/0E0/0/;
#		print "\tInvoice Layout Items - $Cnt\n";

#      delete invoice_layouts

		$Cnt = $dbh->do("delete from invoice_layouts where acct_id='$Acct_id'");
		$Cnt =~ s/0E0/0/;
#		print "\tInvoice Layouts - $Cnt\n";

#      delete invoices

		$Invs = $dbh->do("delete from invoices where acct_id='$Acct_id'");
		$Invs =~ s/0E0/0/;
#		print "\tInvoices - $Cnt\n";

#      delete items

		$Cnt = $dbh->do("delete from items where acct_id='$Acct_id'");
		$Cnt =~ s/0E0/0/;
#		print "\tItems - $Cnt\n";

#      delete journals

		$Cnt = $dbh->do("delete from journals where acct_id='$Acct_id'");
		$Cnt =~ s/0E0/0/;
#		print "\tJournals - $Cnt\n";

#      delete nominals

		$Cnt = $dbh->do("delete from nominals where acct_id='$Acct_id'");
		$Cnt =~ s/0E0/0/;
#		print "\tNominals - $Cnt\n";

#      delete products

		$Cnt = $dbh->do("delete from products where acct_id='$Acct_id'");
		$Cnt =~ s/0E0/0/;
#		print "\tProducts - $Cnt\n";

#      delete recpayments

		$Cnt = $dbh->do("delete from recpayments where acct_id='$Acct_id'");
		$Cnt =~ s/0E0/0/;
#		print "\tRecpayments - $Cnt\n";

#      delete reg_coms		reg1_id+com_id

		$Cnt = $dbh->do("delete from reg_coms where reg1_id=$Reg->{reg_id} and com_id=$Com->{id}");
		$Cnt =~ s/0E0/0/;
#		print "\tReg Coms - $Cnt\n";

#      delete reminders

		$Cnt = $dbh->do("delete from reminders where acct_id='$Acct_id'");
		$Cnt =~ s/0E0/0/;
#		print "\tReminders - $Cnt\n";

#      delete statements

		$Cnt = $dbh->do("delete from statements where acct_id='$Acct_id'");
		$Cnt =~ s/0E0/0/;
#		print "\tStatements - $Cnt\n";

#      delete subscriptions

		$Cnt = $dbh->do("delete from subscriptions where acct_id='$Acct_id'");
		$Cnt =~ s/0E0/0/;
#		print "\tSubscriptions - $Cnt\n";

#      delete tempstacks

		$Cnt = $dbh->do("delete from tempstacks where acct_id='$Acct_id'");
		$Cnt =~ s/0E0/0/;
#		print "\tTempstacks - $Cnt\n";

#      delete transactions

		$Cnt = $dbh->do("delete from transactions where acct_id='$Acct_id'");
		$Cnt =~ s/0E0/0/;
#		print "\tTransactions - $Cnt\n";

#      delete vataccruals

		$Cnt = $dbh->do("delete from vataccruals where acct_id='$Acct_id'");
		$Cnt =~ s/0E0/0/;
#		print "\tVat Accruals - $Cnt\n";

#      delete vatperiods

		$Cnt = $dbh->do("delete from vatperiods where acct_id='$Acct_id'");
		$Cnt =~ s/0E0/0/;
#		print "\tVat Periods - $Cnt\n";

#      delete vatreturns

		$Cnt = $dbh->do("delete from vatreturns where acct_id='$Acct_id'");
		$Cnt =~ s/0E0/0/;
#		print "\tVat Returns - $Cnt\n";

#    delete companies

		$Cnt = $dbh->do("delete from companies where id=$Com->{id} and reg_id = $Reg->{reg_id}");
		$Cnt =~ s/0E0/0/;
#		print "\tCompanies - $Cnt\n";

#######  Print the Deleted User detail

		if ($Reg->{reg_id} != 6142) {
#			print "\n$Acct_id\t$Reg->{regusername}\t$Com->{comname}\t$Reg->{mem}\t$Reg->{reg}\t$Reg->{last}\t$Reg->{diff}\t$Invs\n";
			write;
		}
	}

#  delete registrations

	$Cnt = $dbh->do("delete from registrations where reg_id = $Reg->{reg_id}");
	$Cnt =~ s/0E0/0/;
#	print "\tRegistrations - $Cnt\n";

}
print "\n\nTotal number Deleted = $Deleted_users\n";
$Coms->finish;
$Regs->finish;
$dbh->disconnect;
exit;
