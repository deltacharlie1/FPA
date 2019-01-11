#!/usr/bin/perl

use CGI;
use DBI;
$dbh = DBI->connect("DBI:mysql:fpa3");
$Reg_id = 5774;
$Com_id = 5787;
$acct_id = "$Reg_id+$Com_id";
open(FILE,">/tmp/$Com_id.txt");

$Table = $dbh->prepare("select * from registrations where reg_id=$Reg_id");
$Table->execute;

while (@Row = $Table->fetchrow) {
	$Line = "insert ignore into registrations values (";
	for ($i=0;$i<=$#Row;$i++) {
		if ($i =~ /^0$|^12$|^18$|^20$/) {
			if (length($Row[$i]) > 0) {
				$Line .= "$Row[$i],";
			}
			else {
				$Line .= "NULL,";
			}
		}
		else {
			$Line .= "'$Row[$i]',";
		}
	}
	chop($Line);
	print FILE "$Line);\n";
}
$Table = $dbh->prepare("select * from companies where id=$Com_id");
$Table->execute;

while (@Row = $Table->fetchrow) {
	$Line = "insert ignore into companies values (";
	for ($i=0;$i<=$#Row;$i++) {
		if ($i =~ /^0$|^1$|^35$|^43$|^46$|^47$|^48$|^60$/) {
			if (length($Row[$i]) > 0) {
				$Line .= "$Row[$i],";
			}
			else {
				$Line .= "NULL,";
			}
		}
		else {
			$Line .= "'$Row[$i]',";
		}
	}
	chop($Line);
	print FILE "$Line);\n";
}
$Table = $dbh->prepare("select * from nominals where acct_id='$acct_id'");
$Table->execute;

while (@Row = $Table->fetchrow) {
	$Line = "insert ignore into nominals values (";
	for ($i=0;$i<=$#Row;$i++) {
		if ($i =~ /^0$|^2$|^3$|^9$/) {
			if (length($Row[$i]) > 0) {
				$Line .= "$Row[$i],";
			}
			else {
				$Line .= "NULL,";
			}
		}
		else {
			$Line .= "'$Row[$i]',";
		}
	}
	chop($Line);
	print FILE "$Line);\n";
}

$Table = $dbh->prepare("select * from accounts where acct_id='$acct_id'");
$Table->execute;

while (@Row = $Table->fetchrow) {
	$Line = "insert ignore into accounts values (";
	for ($i=0;$i<=$#Row;$i++) {
		if ($i =~ /^0$|^8$/) {
			if (length($Row[$i]) > 0) {
				$Line .= "$Row[$i],";
			}
			else {
				$Line .= "NULL,";
			}
		}
		else {
			$Line .= "'$Row[$i]',";
		}
	}
	chop($Line);
	print FILE "$Line);\n";
}

$Table = $dbh->prepare("select * from audit_trails where acct_id='$acct_id'");
$Table->execute;

while (@Row = $Table->fetchrow) {
	$Line = "insert ignore into audit_trails values (";
	for ($i=0;$i<=$#Row;$i++) {
		if ($i =~ /^1$|^7$/) {
			if (length($Row[$i]) > 0) {
				$Line .= "$Row[$i],";
			}
			else {
				$Line .= "NULL,";
			}
		}
		else {
			$Line .= "'$Row[$i]',";
		}
	}
	chop($Line);
	print FILE "$Line);\n";
}

$Table = $dbh->prepare("select * from coas where acct_id='$acct_id'");
$Table->execute;

while (@Row = $Table->fetchrow) {
	$Line = "insert ignore into coas values (";
	for ($i=0;$i<=$#Row;$i++) {
		if ($i =~ /^0$|^8$/) {
			if (length($Row[$i]) > 0) {
				$Line .= "$Row[$i],";
			}
			else {
				$Line .= "NULL,";
			}
		}
		else {
			$Line .= "'$Row[$i]',";
		}
	}
	chop($Line);
	print FILE "$Line);\n";
}

$Table = $dbh->prepare("select * from customers where acct_id='$acct_id'");
$Table->execute;

while (@Row = $Table->fetchrow) {
	$Line = "insert ignore into customers values (";
	for ($i=0;$i<=$#Row;$i++) {
		if ($i =~ /^0$|^27$|^29$/) {
			if (length($Row[$i]) > 0) {
				$Line .= "$Row[$i],";
			}
			else {
				$Line .= "NULL,";
			}
		}
		else {
			$Line .= "'$Row[$i]',";
		}
	}
	chop($Line);
	print FILE "$Line);\n";
}

$Table = $dbh->prepare("select * from images where acct_id='$acct_id'");
$Table->execute;

while (@Row = $Table->fetchrow) {
	$Line = "insert ignore into images values (";
	for ($i=0;$i<=$#Row;$i++) {
		if ($i =~ /^0$|^1$|^7$|^8$|^10$/) {
			if (length($Row[$i]) > 0) {
				$Line .= "$Row[$i],";
			}
			else {
				$Line .= "NULL,";
			}
		}
		else {
			$Line .= "'$Row[$i]',";
		}
	}
	chop($Line);
	print FILE "$Line);\n";
}

$Table = $dbh->prepare("select * from inv_txns where acct_id='$acct_id'");
$Table->execute;

while (@Row = $Table->fetchrow) {
	$Line = "insert ignore into inv_txns values (";
	for ($i=0;$i<=$#Row;$i++) {
		if ($i =~ /^0$|^2$|^3$|^10$/) {
			if (length($Row[$i]) > 0) {
				$Line .= "$Row[$i],";
			}
			else {
				$Line .= "NULL,";
			}
		}
		else {
			$Line .= "'$Row[$i]',";
		}
	}
	chop($Line);
	print FILE "$Line);\n";
}

#$Table = $dbh->prepare("select * from invoice_templates where acct_id='$acct_id'");
$Table = $dbh->prepare("select * from invoices where acct_id='$acct_id'");
$Table->execute;

while (@Row = $Table->fetchrow) {
	$Line = "insert ignore into invoices values (";
	for ($i=0;$i<=$#Row;$i++) {
		if ($i =~ /^0$|^2$|^29$|^39$|^41$/) {
			if (length($Row[$i]) > 0) {
				$Line .= "$Row[$i],";
			}
			else {
				$Line .= "NULL,";
			}
		}
		else {
			$Line .= "'$Row[$i]',";
		}
	}
	chop($Line);
	print FILE "$Line);\n";
}

$Table = $dbh->prepare("select * from items where acct_id='$acct_id'");
$Table->execute;

while (@Row = $Table->fetchrow) {
	$Line = "insert ignore into items values (";
	for ($i=0;$i<=$#Row;$i++) {
		if ($i =~ /^0$|^2$|^13$/) {
			if (length($Row[$i]) > 0) {
				$Line .= "$Row[$i],";
			}
			else {
				$Line .= "NULL,";
			}
		}
		else {
			$Line .= "'$Row[$i]',";
		}
	}
	chop($Line);
	print FILE "$Line);\n";
}

$Table = $dbh->prepare("select * from reminders where acct_id='$acct_id'");
$Table->execute;

while (@Row = $Table->fetchrow) {
	$Line = "insert ignore into reminders values (";
	for ($i=0;$i<=$#Row;$i++) {
		if ($i =~ /^0$|^7$/) {
			if (length($Row[$i]) > 0) {
				$Line .= "$Row[$i],";
			}
			else {
				$Line .= "NULL,";
			}
		}
		else {
			$Line .= "'$Row[$i]',";
		}
	}
	chop($Line);
	print FILE "$Line);\n";
}

#$Table = $dbh->prepare("select * from statements where acct_id='$acct_id'");
$Table = $dbh->prepare("select * from tempstacks where acct_id='$acct_id'");
$Table->execute;

while (@Row = $Table->fetchrow) {
	$Line = "insert ignore into tempstacks values (";
	for ($i=0;$i<=$#Row;$i++) {
		if ($i =~ /^0$|^12$/) {
			if (length($Row[$i]) > 0) {
				$Line .= "$Row[$i],";
			}
			else {
				$Line .= "NULL,";
			}
		}
		else {
			$Line .= "'$Row[$i]',";
		}
	}
	chop($Line);
	print FILE "$Line);\n";
}

$Table = $dbh->prepare("select * from transactions where acct_id='$acct_id'");
$Table->execute;

while (@Row = $Table->fetchrow) {
	$Line = "insert ignore into transactions values (";
	for ($i=0;$i<=$#Row;$i++) {
		if ($i =~ /^0$|^2$|^3$|^15$/) {
			if (length($Row[$i]) > 0) {
				$Line .= "$Row[$i],";
			}
			else {
				$Line .= "NULL,";
			}
		}
		else {
			$Line .= "'$Row[$i]',";
		}
	}
	chop($Line);
	print FILE "$Line);\n";
}

#$Table = $dbh->prepare("select * from vataccruals where acct_id='$acct_id'");
#$Table = $dbh->prepare("select * from vatreturns where acct_id='$acct_id'");


#$Table = $dbh->prepare("select * from add_users where addcom_id=$Company[0]");
$Table = $dbh->prepare("select * from reg_coms where reg1_id=$Reg_id");
$Table->execute;

while (@Row = $Table->fetchrow) {
	$Line = "insert ignore into reg_coms values (";
	for ($i=0;$i<=$#Row;$i++) {
		if ($i =~ /^0$|^1$|^2$|^3$|^9$/) {
			if (length($Row[$i]) > 0) {
				$Line .= "$Row[$i],";
			}
			else {
				$Line .= "NULL,";
			}
		}
		else {
			$Line .= "'$Row[$i]',";
		}
	}
	chop($Line);
	print FILE "$Line);\n";
}

close(FILE);

$dbh->disconnect;
exit;
