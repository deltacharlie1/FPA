#!/usr/bin/perl

#  Script to read in the base test data (1 registration, 1 company, and 9 customers)

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");

open(FILE,"<../other/fpa_data.db");

while (<FILE>) {
	tr/\r\n//d;
	s/\'/\\\'/g;
	@Cell = split(/\t/,$_);

	if ($Cell[0] =~ /^REG/i) {

#  Registration

		$Sts = $dbh->do("insert into registrations (reg_id,regusername,regcompanyname,regemail,regpwd,regmemword,regmembership,regactive) values ($Cell[1],'$Cell[2]','$Cell[3]','$Cell[4]','$Cell[5]','$Cell[6]','$Cell[7]','C')");
	}
	elsif ($Cell[0] =~ /^RCO/i) {

#  Reg_coms

		$Sts = $dbh->do("insert into reg_coms (id,reg1_id,reg2_id,com_id,comname) values ($Cell[1],$Cell[2],$Cell[3],$Cell[4],'$Cell[5]')");
	}
	elsif ($Cell[0] =~ /^ACC/i) {

#  Accounts

		$Sts = $dbh->do("insert into accounts (id,acct_id,acctype,accname,accsort,accacctno) values ($Cell[1],'$Cell[2]','$Cell[3]','$Cell[4]','$Cell[5]','$Cell[6]')");
	}
	elsif ($Cell[0] =~ /^COM/i) {

#  Companies

		$Cell[5] =~ s/\|\|/\n/g;
		$Sts = $dbh->do("insert into companies (id,reg_id,comregno,comname,comaddress,compostcode,comtel,combusiness,comcontact,comemail,comyearend,comvatscheme,comvatno,comvatduein) values ($Cell[1],$Cell[2],'$Cell[3]','$Cell[4]','$Cell[5]','$Cell[6]','$Cell[7]','$Cell[8]','$Cell[9]','$Cell[10]','$Cell[11]','$Cell[12]','$Cell[13]','$Cell[14]')");
	}
	elsif ($Cell[0] =~ /^CUS/i) {

#  Customers

		$Cell[4] =~ s/\|\|/\n/g;
		$STS = $dbh->do("insert into customers (id,acct_id,cusname,cusaddress,cuspostcode,cusregion,custel,cuscontact,cusemail,custerms,cusdefpo,cusdefpaymethod,cussales,cussupplier) values ($Cell[1],'$Cell[2]','$Cell[3]','$Cell[4]','$Cell[5]','$Cell[6]','$Cell[7]','$Cell[8]','$Cell[9]','$Cell[10]','$Cell[11]','$Cell[12]','$Cell[13]','$Cell[14]')");
	}
}
$dbh->disconnect;
exit;
