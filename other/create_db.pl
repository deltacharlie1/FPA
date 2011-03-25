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
		$Tag = "";
		$TData = "";
		$Fld{starec_no} = '0';
#		$VAT_id = 0;
	}
	elsif (/^\s*\<\/Registration Details>$/i) {
		$Flds =~ s/,$//;
		$Data =~ s/,$//;

		$Sts = $dbh->do("insert into registrations ($Flds) values ($Data)");
		$Reg_id = $dbh->last_insert_id(undef, undef, qw(registrations undef));
	}
	elsif (/^\s*\<\/Company Details>$/i) {
		$Flds .= "reg_id"; 
		$Data .= $Reg_id;

		$Sts = $dbh->do("insert into companies ($Flds) values ($Data)");
		$Com_id = $dbh->last_insert_id(undef, undef, qw(companies undef));
		$Acct_id = "$Reg_id+$Com_id";

		$Sts = $dbh->do("insert into reg_coms (reg1_id,reg2_id,com_id,comname) values ($Reg_id,$Reg_id,$Com_id,'$Fld{comname}')");
	}
	elsif (/^\s*\<\/COA Details/i) {
		$Flds .= "acct_id"; 
		$Data .= "'$Acct_id'";
		$Sts = $dbh->do("insert into coas ($Flds) values ($Data)");
		$Sts = $dbh->do("update coas set coabalance='0.00' where acct_id='$Acct_id' and coanominalcode='$Fld{coanominalcode}'");
	}
	elsif (/^\s*\<\/Account Details/i) {
		$Flds .= "acct_id"; 
		$Data .= "'$Acct_id'";
		$Sts = $dbh->do("insert into accounts ($Flds) values ($Data)");
		$Acc_id = $dbh->last_insert_id(undef, undef, qw(accounts undef));
	}
	elsif (/^\s*\<\/Statement Details/i) {
		$Flds .= "acct_id,acc_id,starec_no"; 
		$Data .= "'$Acct_id',$Acc_id,'$Fld{starec_no}'";
		$Sts = $dbh->do("insert into statements ($Flds) values ($Data)");
		$Stmt_id = $dbh->last_insert_id(undef, undef, qw(statements undef));
	}
	elsif (/^\s*\<\/Statement Transaction Details/i) {
		$Flds .= "acct_id,link_id,stmt_id"; 
		$Data .= "'$Acct_id',$Stmt_id,$Stmt_id";
		$Sts = $dbh->do("insert into transactions ($Flds) values ($Data)");
		$Txn_id = $dbh->last_insert_id(undef, undef, qw(transactions undef));

		$Sts = $dbh->do("insert into nominals (acct_id,link_id,nomtype,nomcode,nomamount,nomdate) values ('$Acct_id',$Txn_id,'T','$Fld{txnmethod}','$Fld{txnamount}','$Fld{txndate}')");
		$Sts = $dbh->do("update coas set coabalance=coabalance+'$Fld{txnamount}' where acct_id='$Acct_id' and coanominalcode='$Fld{txnmethod}'");
		if ($Fld{txnamount} < 0) {
			$Sts = $dbh->do("insert into nominals (acct_id,link_id,nomtype,nomcode,nomamount,nomdate) values ('$Acct_id',$Txn_id,'T','6000','0'-'$Fld{txnamount}','$Fld{txndate}')");
			$Sts = $dbh->do("update coas set coabalance=coabalance-'$Fld{txnamount}' where acct_id='$Acct_id' and coanominalcode='6000'");
		}
		else {
			$Sts = $dbh->do("insert into nominals (acct_id,link_id,nomtype,nomcode,nomamount,nomdate) values ('$Acct_id',$Txn_id,'T','4300','0'-'$Fld{txnamount}','$Fld{txndate}')");
			$Sts = $dbh->do("update coas set coabalance=coabalance-'$Fld{txnamount}' where acct_id='$Acct_id' and coanominalcode='4300'");
		}
	}
	elsif (/^\s*\<\/Opening Balance Details/i) {
		$Flds .= "acct_id"; 
		$Data .= "'$Acct_id'";
		$Sts = $dbh->do("insert into transactions ($Flds) values ($Data)");
		$Txn_id = $dbh->last_insert_id(undef, undef, qw(transactions undef));

		$Sts = $dbh->do("insert into nominals (acct_id,link_id,nomtype,nomcode,nomamount,nomdate) values ('$Acct_id',$Txn_id,'T','$Fld{txnmethod}','$Fld{txnamount}','$Fld{txndate}')");
		$Sts = $dbh->do("update coas set coabalance=coabalance+'$Fld{txnamount}' where acct_id='$Acct_id' and coanominalcode='$Fld{txnmethod}'");
		$Sts = $dbh->do("insert into nominals (acct_id,link_id,nomtype,nomcode,nomamount,nomdate) values ('$Acct_id',$Txn_id,'T','3100','$Fld{txnamount}','$Fld{txndate}')");
		$Sts = $dbh->do("update coas set coabalance=coabalance+'$Fld{txnamount}' where acct_id='$Acct_id' and coanominalcode='3100'");
	}
	elsif (/^\s*\<\/VAT Return Details/i) {
		$Flds .= "acct_id"; 
		$Data .= "'$Acct_id'";
		$Sts = $dbh->do("insert into vatreturns ($Flds) values ($Data)");
		$VAT_id = $dbh->last_insert_id(undef, undef, qw(vatreturns undef));
	}
	elsif (/^\s*\<\/VAT Accrual Details/i) {
		if ($Fld{comvatscheme} =~ /C/i) {
			@Txnid = $dbh->selectrow_array("select id from transactions where acct_id='$Acct_id' and txntxnno='$Fld{acrtxn_no}'");
		}
		else {
			@Txnid = $dbh->selectrow_array("select id from invoices where acct_id='$Acct_id' and invinvoiceno='$Fld{acrtxn_no}'");
		}
		$Flds .= "acct_id,vr_id,acrtxn_id"; 
		$Data .= "'$Acct_id',$VAT_id,$Txnid[0]";
		$Sts = $dbh->do("insert into vataccruals ($Flds) values ($Data)");
#		print "\$Sts = \$dbh->do(\"insert into vataccruals ($Flds) values ($Data)\")\n";
	}
	elsif (/^\s*\<\/VAT Transaction Details/i) {
		@Stmt = $dbh->selectrow_array("select id from statements where acct_id='$Acct_id' and starec_no='$Fld{starec_no}'");
		$Flds .= "acct_id,link_id,stmt_id"; 
		$Data .= "'$Acct_id',$VAT_id,$Stmt[0]";
		$Sts = $dbh->do("insert into transactions ($Flds) values ($Data)");
		$Txn_id = $dbh->last_insert_id(undef, undef, qw(transactions undef));

		$Sts = $dbh->do("insert into nominals (acct_id,link_id,nomtype,nomcode,nomamount,nomdate) values ('$Acct_id',$Txn_id,'T','$Fld{txnmethod}','$Fld{txnamount}','$Fld{txndate}')");
		$Sts = $dbh->do("update coas set coabalance=coabalance+'$Fld{txnamount}' where acct_id='$Acct_id' and coanominalcode='$Fld{txnmethod}'");

		$Sts = $dbh->do("insert into nominals (acct_id,link_id,nomtype,nomcode,nomamount,nomdate) values ('$Acct_id',$Txn_id,'T','2100','0'-'$Fld{perbox3}','$Fld{txndate}')");
		$Sts = $dbh->do("update coas set coabalance=coabalance-'$Fld{perbox3}' where acct_id='$Acct_id' and coanominalcode='2100'");

		$Sts = $dbh->do("insert into nominals (acct_id,link_id,nomtype,nomcode,nomamount,nomdate) values ('$Acct_id',$Txn_id,'T','1400','0'-'$Fld{perbox4}','$Fld{txndate}')");
		$Sts = $dbh->do("update coas set coabalance=coabalance-'$Fld{perbox4}' where acct_id='$Acct_id' and coanominalcode='1400'");
	}
	elsif (/^\s*\<\/Customer Details/i) {
		$Flds .= "acct_id"; 
		$Data .= "'$Acct_id'";
		$Sts = $dbh->do("insert into customers ($Flds) values ($Data)");
		$Cus_id = $dbh->last_insert_id(undef, undef, qw(customers undef));
	}
	elsif (/^\s*\<\/Customer Invoice Details/i) {
		$Flds .= "acct_id,cus_id"; 
		$Data .= "'$Acct_id',$Cus_id";
		$Sts = $dbh->do("insert into invoices ($Flds) values ($Data)");
#unless ($Sts > 0) {
#		print "\$Sts = \$dbh->do(\"insert into invoices ($Flds) values ($Data)\")\n";
#}
		$Inv_id = $dbh->last_insert_id(undef, undef, qw(invoices undef));


		if ($Fld{invtype} =~ /S|C/i) {
			$Sts = $dbh->do("insert into nominals (acct_id,link_id,nomtype,nomcode,nomamount,nomdate) values ('$Acct_id',$Inv_id,'S','$Fld{invcoa}','$Fld{invtotal}','$Fld{invprintdate}')");
			$Sts = $dbh->do("update coas set coabalance=coabalance+'$Fld{invtotal}' where acct_id='$Acct_id' and coanominalcode='$Fld{invcoa}'");
			if ($Fld{invvat} && $Fld{comvatscheme} !~ /N/i) {
				$Sts = $dbh->do("insert into nominals (acct_id,link_id,nomtype,nomcode,nomamount,nomdate) values ('$Acct_id',$Inv_id,'S','2100','$Fld{invvat}','$Fld{invprintdate}')");
				$Sts = $dbh->do("update coas set coabalance=coabalance+'$Fld{invvat}' where acct_id='$Acct_id' and coanominalcode='2100'");
			}
			$Sts = $dbh->do("insert into nominals (acct_id,link_id,nomtype,nomcode,nomamount,nomdate) values ('$Acct_id',$Inv_id,'S','1100','$Fld{invtotal}'+'$Fld{invvat}','$Fld{invprintdate}')");
			$Sts = $dbh->do("update coas set coabalance=coabalance+'$Fld{invtotal}'+'$Fld{invvat}' where acct_id='$Acct_id' and coanominalcode='1100'");
		}
		else {
			$Sts = $dbh->do("insert into nominals (acct_id,link_id,nomtype,nomcode,nomamount,nomdate) values ('$Acct_id',$Inv_id,'S','$Fld{invcoa}','0'-'$Fld{invtotal}','$Fld{invprintdate}')");
			$Sts = $dbh->do("update coas set coabalance=coabalance-'$Fld{invtotal}' where acct_id='$Acct_id' and coanominalcode='$Fld{invcoa}'");
			if ($Fld{invvat} && $Fld{comvatscheme} !~ /N/i) {
				$Sts = $dbh->do("insert into nominals (acct_id,link_id,nomtype,nomcode,nomamount,nomdate) values ('$Acct_id',$Inv_id,'S','1400','0'-'$Fld{invvat}','$Fld{invprintdate}')");
				$Sts = $dbh->do("update coas set coabalance=coabalance-'$Fld{invvat}' where acct_id='$Acct_id' and coanominalcode='1400'");
			}
			$Sts = $dbh->do("insert into nominals (acct_id,link_id,nomtype,nomcode,nomamount,nomdate) values ('$Acct_id',$Inv_id,'S','2000','$Fld{invtotal}'+'$Fld{invvat}','$Fld{invprintdate}')");
			$Sts = $dbh->do("update coas set coabalance=coabalance+'$Fld{invtotal}'+'$Fld{invvat}' where acct_id='$Acct_id' and coanominalcode='2000'");
		}
		$Sts = $dbh->do("update customers set cusbalance=cusbalance+'$Fld{invtotal}'+'$Fld{invvat}' where acct_id='$Acct_id' and id=$Cus_id");
		if ($Fld{comvatscheme} =~ /S/i) {
			$Sts = $dbh->do("update companies set comvatcontrol=comvatcontrol+'$Fld{invvat}' where reg_id=$Reg_id and id=$Com_id");
			$Vatreturns = $dbh->prepare("select id from vatreturns where $Fld{invprintdate}>=perstartdate and $Fld{invprintdate}<=perenddate and acct_id='$Acct_id'");
			$Vatreturns->execute;
			($Vr_id) = $Vatreturns->fetchrow;
			$Sts = $dbh->do("insert into vataccruals (vr_id,acct_id,acrtotal,acrvat,acrtype,acrprintdate,acrnominalcode,acrtxn_id) values ($Vr_id,'$Acct_id','$Fld{invtotal}','$Fld{invvat}','$Fld{invtype}','$Fld{invprintdate}','$Fld{invcoa}',$Inv_id");
		}
	}
	elsif (/^\s*\<\/Customer Transaction Details/i) {
		@Stmt = $dbh->selectrow_array("select id from statements where acct_id='$Acct_id' and starec_no='$Fld{starec_no}'");
		$Flds .= "acct_id,link_id,stmt_id"; 
		$Data .= "'$Acct_id',$Cus_id,$Stmt[0]";
		$Sts = $dbh->do("insert into transactions ($Flds) values ($Data)");
		$Txn_id = $dbh->last_insert_id(undef, undef, qw(transactions undef));
		if ($Fld{txnmethod} =~ /1310/) {
			$Sts = $dbh->do("update companies set comnocheques=comnocheques+1 where reg_id=$Reg_id and id=$Com_id");
		}
		$Sts = $dbh->do("insert into nominals (acct_id,link_id,nomtype,nomcode,nomamount,nomdate) values ('$Acct_id',$Txn_id,'T','$Fld{txnmethod}','$Fld{txnamount}','$Fld{txndate}')");
		$Sts = $dbh->do("update coas set coabalance=coabalance+'$Fld{txnamount}' where acct_id='$Acct_id' and coanominalcode='$Fld{txnmethod}'");
		if ($Fld{txntxntype} =~ /income/) {
			$Sts = $dbh->do("insert into nominals (acct_id,link_id,nomtype,nomcode,nomamount,nomdate) values ('$Acct_id',$Txn_id,'T','1100','0'-'$Fld{txnamount}','$Fld{txndate}')");
			$Sts = $dbh->do("update coas set coabalance=coabalance-'$Fld{txnamount}' where acct_id='$Acct_id' and coanominalcode='1100'");
		}
		else {
			$Sts = $dbh->do("insert into nominals (acct_id,link_id,nomtype,nomcode,nomamount,nomdate) values ('$Acct_id',$Txn_id,'T','2000','0'-'$Fld{txnamount}','$Fld{txndate}')");
			$Sts = $dbh->do("update coas set coabalance=coabalance-'$Fld{txnamount}' where acct_id='$Acct_id' and coanominalcode='2000'");
		}
	}
	elsif (/^\s*\<\/Customer Transaction Invoice Details/i) {
		@Inv = $dbh->selectrow_array("select id,invtype from invoices where invinvoiceno='$Fld{itinvoiceno}' and acct_id='$Acct_id'");
		$Flds .= "acct_id,inv_id,txn_id";
		$Data .= "'$Acct_id','$Inv[0]','$Txn_id'";
		$Sts = $dbh->do("insert into inv_txns ($Flds) values ($Data)");
	}
	elsif (/^\s*\<(\w+)?>(.*)<\/\1>$/) {		#  Start and end tags on same line
		$Fldname = $1;
		$Flddata = $2;
		unless ($Fldname =~ /starec_no|acrtxn_no/) {
			$Flds .= $Fldname.",";
			$Data .= "'$Flddata',";
		}
		$Fld{$Fldname} = $Flddata;
	}
	elsif (/^\s*\<(\w+)?>(.+)$/) {			#  Start tag plus data but no end tag
		$Tag .= $1;
		$TData = $2."\n";
	}
	elsif ($Tag && /^\s*(.*)\<\/$Tag>$/) {		#  Data plus end tag but no start tag
		if ($Tag =~ /^64/) {
			$TData = decode_base64($TData);
			$Tag =~ s/^64//;
		}
		$Flds .= $Tag.",";
		$Data .= "'$TData',";
		$Tag = "";
		$TData = "";
	}
	elsif ($Tag && ! /^\s*\<\/$Tag>$/) {		#  in the middle of a multi-line tag
		$TData .= $_;
	}
}
close(FILE);
exit;
