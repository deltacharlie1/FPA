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
$Comexpid = 0;
$Comvatscheme = "";
$Com_id = 0;
$Reg_id = 0;

$XML_file = $ARGV[0] || 'fpadump.xml';

open(FILE,"<$XML_file");
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
	}
	elsif (/^\s*\<\/Company Details>$/i) {
		$Comexpid = $Fld{comexpid};
		$Comvatscheme = $Fld{comvatscheme};
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
		$Sts = $dbh->do("update reg_coms set reg2_id=$Reg_id,com_id=$Com_id where id=$Reg_com_id");
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
	elsif (/^\s*\<\/Tempstack Details/i) {
		$Flds .= "acct_id"; 
		$Data .= "'$Acct_id'";
		$Sts = $dbh->do("insert into tempstacks ($Flds) values ($Data)");
	}

##############  Start of field processing

	elsif (/^\s*\<(\w+)?>(.*)<\/\1>$/) {		#  Start and end tags on same line
		$Fldname = $1;
		$Flddata = $2;

		$Flddata =~ s/\\\\n/\n/g;		#  re-introduce newlines

		if ($Fldname =~ /^64.+/) {
			$Fldname =~ s/^64//;
			$Flddata = decode_base64($Flddata);
		}
		$Flddata =~ s/\'/\\\'/sg;
		$Fld{$Fldname} = $Flddata;

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

$Registrations = $dbh->prepare("select reg_id,old_id from registrations");
$Registrations->execute;
while ($Registration = $Registrations->fetchrow_hashref) {
	$Sts = $dbh->do("update reg_coms set reg1_id=$Registration->{reg_id} where com_id=$Com_id");
}
$Registrations->finish;

$Customers = $dbh->prepare("select id,old_id from customers where acct_id='$Acct_id'");
$Customers->execute;
while ($Customer = $Customers->fetchrow_hashref) {
	$Sts = $dbh->do("update invoices set cus_id=$Customer->{id} where cus_id=$Customer->{old_id} and acct_id='$Acct_id'");
	$Sts = $dbh->do("update transactions set link_id=$Customer->{id} where link_id=$Customer->{old_id} and txncusname not like 'Bank%' and txncusname not like 'VAT%' and acct_id='$Acct_id'");
	if ($Customer->{old_id} == $Comexpid) {
		@Comid = split(/\+/,$Acct_id);
		$Sts = $dbh->do("update companies set comexpid=$Customer->{id} where reg_id=$Comid[0] and id=$Comid[1]");
	}
}
$Customers->finish;

$Invoices = $dbh->prepare("select id,old_id from invoices where acct_id='$Acct_id'");
$Invoices->execute;
while ($Invoice = $Invoices->fetchrow_hashref) {
	$Sts = $dbh->do("update items set inv_id=$Invoice->{id} where inv_id=$Invoice->{old_id} and acct_id='$Acct_id'");
	$Sts = $dbh->do("update transactions set link_id=$Invoice->{id} where link_id=$Invoice->{old_id} and txncusname like 'Bank%' and acct_id='$Acct_id'");
	$Sts = $dbh->do("update inv_txns set inv_id=$Invoice->{id} where inv_id=$Invoice->{old_id} and acct_id='$Acct_id'");
	$Sts = $dbh->do("update nominals set link_id=$Invoice->{id} where link_id=$Invoice->{old_id} and nomtype='S' and acct_id='$Acct_id'");
	$Sts = $dbh->do("update audit_trails set link_id=$Invoice->{id},audstamp=audstamp where link_id=$Invoice->{old_id} and audtype like 'update%' and acct_id='$Acct_id'");
	$Sts = $dbh->do("update images set link_id=$Invoice->{id} where link_id=$Invoice->{old_id} and imgdoc_type='INV' and acct_id='$Acct_id'");
	if ($Comvatscheme =~ /S/i) {
		$Sts = $dbh->do("update vataccruals set acrtxn_id=$Invoice->{id} where acrtxn_id=$Invoice->{old_id} and acct_id='$Acct_id'");
	}
}
$Invoices->finish;

$Transactions = $dbh->prepare("select id,old_id from transactions where acct_id='$Acct_id'");
$Transactions->execute;
while ($Transaction = $Transactions->fetchrow_hashref) {
	$Sts = $dbh->do("update inv_txns set txn_id=$Transaction->{id} where txn_id=$Transaction->{old_id} and acct_id='$Acct_id'");
	$Sts = $dbh->do("update nominals set link_id=$Transaction->{id} where link_id=$Transaction->{old_id} and nomtype='T' and acct_id='$Acct_id'");
	$Sts = $dbh->do("update images set link_id=$Transaction->{id} where link_id=$Transaction->{old_id} and imgdoc_type='TXN' and acct_id='$Acct_id'");
	$Sts = $dbh->do("update audit_trails set link_id=$Transaction->{id},audstamp=audstamp where link_id=$Transaction->{old_id} and audtype like 'transac%' and acct_id='$Acct_id'");
}
$Transactions->finish;

if ($Comvatscheme =~ /C/i) {
	$Inv_txns = $dbh->prepare("select id,old_id from inv_txns where acct_id='$Acct_id'");
	$Inv_txns->execute;
	while ($Inv_txn = $Inv_txns->fetchrow_hashref) {
		$Sts = $dbh->do("update vataccruals set acrtxn_id=$Inv_txn->{id} where acrtxn_id=$Inv_txn->{old_id} and acct_id='$Acct_id'");
	}
	$Inv_txns->finish;
}

$Accounts = $dbh->prepare("select id,old_id from accounts where acct_id='$Acct_id'");
$Accounts->execute;
while ($Account = $Accounts->fetchrow_hashref) {
	$Sts = $dbh->do("update statements set acc_id=$Account->{id} where acc_id=$Account->{old_id} and acct_id='$Acct_id'");
}
$Accounts->finish;
$Statements = $dbh->prepare("select id,old_id from statements where acct_id='$Acct_id'");
$Statements->execute;
while ($Statement = $Statements->fetchrow_hashref) {
	$Sts = $dbh->do("update transactions set stmt_id=$Statement->{id} where stmt_id=$Statement->{old_id} and acct_id='$Acct_id'");
	$Sts = $dbh->do("update images set link_id=$Statement->{id} where link_id=$Statement->{old_id} and imgdoc_type='STMT' and acct_id='$Acct_id'");
}
$Statements->finish;
$Vatreturns = $dbh->prepare("select id,old_id from vatreturns where acct_id='$Acct_id'");
$Vatreturns->execute;
while ($Vatreturn = $Vatreturns->fetchrow_hashref) {
	$Sts = $dbh->do("update vataccruals set vr_id=$Vatreturn->{id} where vr_id=$Vatreturn->{old_id} and acct_id='$Acct_id'");
	$Sts = $dbh->do("update transactions set link_id=$Vatreturn->{id} where link_id=$Vatreturn->{old_id} and txncusname like 'VAT%' and acct_id='$Acct_id'");
	$Sts = $dbh->do("update audit_trails set link_id=$Vatreturn->{id},audstamp=audstamp where link_id=$Vatreturn->{old_id} and audtype like 'vatreturn%' and acct_id='$Acct_id'");
}
$Vatreturns->finish;
$dbh->disconnect;

exit;
