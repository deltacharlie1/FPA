#!/usr/bin/perl

#  Script to add dumped details into a FreePlus database

use MIME::Base64;
use DBI;
$dbh = DBI->connect("DBI:mysql:fpa");

$Flds = "";
$Data = "";
$Acct_id = "";
$VAT_id = 0;
$Field = "";

open(FILE,"<fpadump.xml");
while (<FILE>) {
	if (/^\s*\<\w.+ Details>$/i) {
		$Flds = "";
		$Data = "";
	}
	elsif (/^\s*\<\/Registration Details>$/i) {
		$Flds =~ s/,$//;
		$Data =~ s/,$//;
		$Sts = $dbh->do("insert into registrations ($Flds) values ($Data)");
		$Reg_id = $dbh->last_insert_id(undef, undef, qw(registrations undef));
		if ($Reg_com_id) {
			$Sts = $dbh->do("update reg_coms set reg1_id=$Reg_com_id where old_id=$Fld{reg1_id}");
		} 

	}
	elsif (/^\s*\<\/Company Details>$/i) {
		$Flds =~ s/,$//;
		$Data =~ s/,$//;
		$Sts = $dbh->do("insert into companies ($Flds) values ($Data)");
		$Com_id = $dbh->last_insert_id(undef, undef, qw(companies undef));
		$Sts = $dbh->do("update companies set reg_id=$Reg_id where id=$Com_id");
		$Acct_id = "$Reg_id+$Com_id";
	}
	elsif (/^\s*\<\/Reg Com Details/i) {
		$Flds =~ s/,$//;
		$Data =~ s/,$//;
		$Sts = $dbh->do("insert into reg_coms ($Flds) values ($Data)");
		$Reg_com_id = $dbh->last_insert_id(undef, undef, qw(reg_coms undef));
		$Sts = $dbh->do("update reg_coms set reg2_id=$Com_id,com_id=$Com_id where id=$Reg_com_id");
	}
	elsif (/^\s*\<\/COA Details/i) {
		$Flds .= "acct_id"; 
		$Data .= "'$Acct_id'";
		$Sts = $dbh->do("insert into coas ($Flds) values ($Data)");
	}
	elsif (/^\s*\<\/Account Details/i) {
		$Flds .= "acct_id"; 
		$Data .= "'$Acct_id'";
		$Sts = $dbh->do("insert into accounts ($Flds) values ($Data)");
	}
	elsif (/^\s*\<\/Statement Details/i) {
		$Flds .= "acct_id"; 
		$Data .= "'$Acct_id'";
		$Sts = $dbh->do("insert into statements ($Flds) values ($Data)");
	}
	elsif (/^\s*\<\/VAT Return Details/i) {
		$Flds .= "acct_id"; 
		$Data .= "'$Acct_id'";
		$Sts = $dbh->do("insert into vatreturns ($Flds) values ($Data)");
	}
	elsif (/^\s*\<\/Customer Details/i) {
		$Flds .= "acct_id"; 
		$Data .= "'$Acct_id'";
		$Sts = $dbh->do("insert into customers ($Flds) values ($Data)");
	}
	elsif (/^\s*\<\/Customer Invoice Details/i) {
		$Flds .= "acct_id"; 
		$Data .= "'$Acct_id'";
		$Sts = $dbh->do("insert into invoices ($Flds) values ($Data)");
	}
	elsif (/^\s*\<\/Invoice Item Details/i) {
		$Flds .= "acct_id"; 
		$Data .= "'$Acct_id'";
		$Sts = $dbh->do("insert into items ($Flds) values ($Data)");
	}
	elsif (/^\s*\<\/Transaction Details/i) {
		$Flds .= "acct_id"; 
		$Data .= "'$Acct_id'";
		$Sts = $dbh->do("insert into transactions ($Flds) values ($Data)");
	}
	elsif (/^\s*\<\/Inv Txn Details/i) {
		$Flds .= "acct_id"; 
		$Data .= "'$Acct_id'";
		$Sts = $dbh->do("insert into inv_txns ($Flds) values ($Data)");
	}
	elsif (/^\s*\<\/Nominal Details/i) {
		$Flds .= "acct_id"; 
		$Data .= "'$Acct_id'";
		$Sts = $dbh->do("insert into nominals ($Flds) values ($Data)");
	}
	elsif (/^\s*\<\/VAT Accrual Details/i) {
		$Flds .= "acct_id"; 
		$Data .= "'$Acct_id'";
		$Sts = $dbh->do("insert into vataccruals ($Flds) values ($Data)");
	}
	elsif (/^\s*\<\/Audit Trail Details/i) {
		$Flds .= "acct_id"; 
		$Data .= "'$Acct_id'";
		$Sts = $dbh->do("insert into audit_trails ($Flds) values ($Data)");
	}
	elsif (/^\s*\<\/Reminder Details/i) {
		$Flds .= "acct_id"; 
		$Data .= "'$Acct_id'";
		$Sts = $dbh->do("insert into reminders ($Flds) values ($Data)");
	}

##############  Start of field processing

	elsif (/^\s*\<(\w+)?>(.*)<\/\1>$/) {		#  Start and end tags on same line
		$Fldname = $1;
		$Flddata = $2;
		$Fld{$Fldname} = $Flddata;
		$Flddata =~ s/\\\\n/\n/g;		#  re-introduce newlines

		if ($Fldname =~ /^64.+/) {
			$Fldname =~ s/^64//;
			$Flddata = decode_base64($Flddata);
		}
		$Flds .= $Fldname.",";
		if ($Fldname =~ /id/i) {
			$Data .= "$Flddata,";
		}
		else {
			$Data .= "'$Flddata',";
		}
	}
}
close(FILE);

#  Now sort out all of the link fields

$Accounts = $dbh->prepare("select id,old_id from accounts where acct_id='$Acct_id'");
$Accounts->execute;
while ($Account = $Accounts->fetchrow_hashref) {
	$Sts = $dbh->do("update statements set acc_id=$Account->{id} where acc_id=$Account->{old_id} and acct_id='$Acct_id'");
}
$Accounts->finish;

$Customers = $dbh->prepare("select id,old_id from customers where acct_id='$Acct_id'");
$Customers->execute;
while ($Customer = $Customers->fetchrow_hashref) {
	$Sts = $dbh->do("update invoices set cus_id=$Customer->{id} where cus_id=$Customer->{old_id} and acct_id='$Acct_id'");
}
$Customers->finish;

$Invoices = $dbh->prepare("select id,old_id from invoices where acct_id='$Acct_id'");
$Invoices->execute;
while ($Invoice = $Invoices->fetchrow_hashref) {
	$Sts = $dbh->do("update transactions set link_id=$Invoice->{id} where link_id=$Invoice->{old_id} and acct_id='$Acct_id'");
	$Sts = $dbh->do("update inv_txns set inv_id=$Invoice->{id} where inv_id=$Invoice->{old_id} and acct_id='$Acct_id'");
	$Sts = $dbh->do("update nominals set link_id=$Invoice->{id} where link_id=$Invoice->{old_id} and nomtype='S' and acct_id='$Acct_id'");
}
$Invoices->finish;
$Statements = $dbh->prepare("select id,old_id from statements where acct_id='$Acct_id'");
$Statements->execute;
while ($Statement = $Statements->fetchrow_hashref) {
	$Sts = $dbh->do("update transactions set stmt_id=$Statement->{id} where stmt_id=$Statement->{old_id} and acct_id='$Acct_id'");
}
$Statements->finish;
$Transactions = $dbh->prepare("select id,old_id from transactions where acct_id='$Acct_id'");
$Transactions->execute;
while ($Transaction = $Transactions->fetchrow_hashref) {
	$Sts = $dbh->do("update inv_txns set txn_id=$Transaction->{id} where txn_id=$Transaction->{old_id} and acct_id='$Acct_id'");
	$Sts = $dbh->do("update nominals set link_id=$Transaction->{id} where link_id=$Transaction->{old_id} and nomtype='T' and acct_id='$Acct_id'");
	$Sts = $dbh->do("update vataccruals set acrtxn_id=$Transaction->{id} where acrtxn_id=$Transaction->{old_id} and acct_id='$Acct_id'");
}
$Transactions->finish;
$Vatreturns = $dbh->prepare("select id,old_id from vatreturns where acct_id='$Acct_id'");
$Vatreturns->execute;
while ($Vatreturn = $Vatreturns->fetchrow_hashref) {
	$Sts = $dbh->do("update vataccruals set vr_id=$Vatreturn->{id} where vr_id=$Vatreturn->{old_id} and acct_id='$Acct_id'");
}
$Vatreturns->finish;
$dbh->disconnect;

exit;
