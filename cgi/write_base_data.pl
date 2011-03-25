#!/usr/bin/perl

#  Script to write out the base test data (1 registration, 1 company, and 9 customers)

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");

open(FILE,">../other/fpa_data.db");

#  Registration

$Regs = $dbh->prepare("select reg_id,regusername,regcompanyname,regemail,regpwd,regmemword,regmembership from registrations");
$Regs->execute;
while (@Reg = $Regs->fetchrow) {
	print FILE "REG\t$Reg[0]\t$Reg[1]\t$Reg[2]\t$Reg[3]\t$Reg[4]\t$Reg[5]\t$Reg[6]\n";
}
$Regs->finish;

#  Reg_coms

$Reg_coms = $dbh->prepare("select id,reg1_id,reg2_id,com_id,comname from reg_coms");
$Reg_coms->execute;
while (@Reg_com = $Reg_coms->fetchrow) {
	print FILE "RCO\t$Reg_com[0]\t$Reg_com[1]\t$Reg_com[2]\t$Reg_com[3]\t$Reg_com[4]\n";
}
$Reg_coms->finish;

#  Companies

$Companies = $dbh->prepare("select id,reg_id,comregno,comname,comaddress,compostcode,comtel,combusiness,comcontact,comemail,comyearend,comvatscheme,comvatno,comvatduein from companies");
$Companies->execute;
while (@Company = $Companies->fetchrow) {
	$Company[4] =~ tr/\r//d;
	$Company[4] =~ s/\n/||/g;
	print FILE "COM\t$Company[0]\t$Company[1]\t$Company[2]\t$Company[3]\t$Company[4]\t$Company[5]\t$Company[6]\t$Company[7]\t$Company[8]\t$Company[9]\t$Company[10]\t$Company[11]\t$Company[12]\t$Company[13]\n"; 
}
$Companies->finish;

#  Accounts

$Accounts = $dbh->prepare("select id,acct_id,acctype,accname,accsort,accacctno from accounts");
$Accounts->execute;
while (@Acc = $Accounts->fetchrow) {
	print FILE "ACC\t$Acc[0]\t$Acc[1]\t$Acc[2]\t$Acc[3]\t$Acc[4]\t$Acc[5]\n";
}
$Accounts->finish;

#  Customers

$Customers = $dbh->prepare("select id,acct_id,cusname,cusaddress,cuspostcode,cusregion,custel,cuscontact,cusemail,custerms,cusdefpo,cusdefpaymethod,cussales,cussupplier from customers");
$Customers->execute;
while (@Customer = $Customers->fetchrow) {
	$Customer[3] =~ tr/\r//d;
	$Customer[3] =~ s/\n/||/g;
	print FILE "CUS\t$Customer[0]\t$Customer[1]\t$Customer[2]\t$Customer[3]\t$Customer[4]\t$Customer[5]\t$Customer[6]\t$Customer[7]\t$Customer[8]\t$Customer[9]\t$Customer[10]\t$Customer[11]\t$Customer[12]\t$Customer[13]\n";
}
$Customers->finish;
$dbh->disconnect;
exit;
