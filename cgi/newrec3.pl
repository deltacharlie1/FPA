#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to update Company Details

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});

use CGI;
use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");

$Data = new CGI;
%FORM = $Data->Vars;

while (( $Key,$Value) = each %FORM) {

#  Remove any bad characters

	$Value =~ tr/\\//d;
	$Value =~ s/\'/\\\'/g;
        $FORM{$Key} = $Value;

}

#  Processing for the following types of input row:-

#  inv - invoice not yet marked as paid - so call process_invoice 
#  txn - transaction already entered - so just store id for linking to statement
#  pur - this is a new money out - process_purchase
#  sal - this is a new money in - process_invoice


# warn "$FORM{stmtdata}\n";

require "/usr/local/git/fpa/cgi/process_invoice.ph";
require "/usr/local/git/fpa/cgi/process_purchase.ph";

$Txn_ids = "";
$New_data = "";
$CFdate = '';
$No_txns = 0;

$FORM{stmtdata} =~ tr/\r\n//d;
@Txn;

while ($FORM{stmtdata} =~ s/^.*?(<tbody id.*?<\/tbody>.*?<\/tbody>)/&Tbody($1)/oegi) {}

#  Create the most recent statement entry

$Stmts = $dbh->prepare("select stastmtno,starec_no,date_add(staclosedate,interval 1 day) as newopendate,accounts.id,accname,accshort from statements left join accounts on (acc_id=accounts.id) where statements.acct_id='$COOKIE->{ACCT}' and acctype='$FORM{txnmethod}' order by staclosedate desc limit 1");
$Stmts->execute;
@Stmt = $Stmts->fetchrow;
$Stmts->finish;

$Stmt[1]++;             #  Increment the reconciliation count no

$Sts = $dbh->do("insert into statements (acct_id,acc_id,staopenbal,staclosebal,stastmtno,staopendate,staclosedate,stanotxns,starec_no) values ('$COOKIE->{ACCT}',$Stmt[3],'$FORM{newopen}','$FORM{newclose}','$FORM{newstmtno}','$Stmt[2]',str_to_date('$CFdate','%d-%b-%y'),'$No_txns',$Stmt[1])");
$New_stmt_id = $dbh->last_insert_id(undef, undef, qw(transactionss undef));

#  update the relevant transactions

chop($Txn_ids);

$Sts = $dbh->do("update transactions set txnselected='F',stmt_id=$New_stmt_id where acct_id='$COOKIE->{ACCT}' and txnmethod='$FORM{txnmethod}' and id in ($Txn_ids)");

#  clear out the tempstacks record

$Sts = $dbh->do("update tempstacks set f1='',f2='',f3='',f4='',f5='',f6='' where acct_id='$COOKIE->{ACCT}' and caller='reconciliation'");

#  finally, add an audit trail record

$Sts = $dbh->do("insert into audit_trails (acct_id,link_id,audtype,audaction,audtext,auduser) values ('$COOKIE->{ACCT}',$New_stmt_id,'newrec.pl','reconcile','$Stmt[4] $Stmt[5] account statement $FORM{newstmtno} reconciled with $No_txns items','$COOKIE->{USER}')");

print<<EOD;
Content-Type: text/html
Status: 302
Location: /cgi-bin/fpa/list_stmt_txns.pl?filter=$New_stmt_id

EOD
$dbh->disconnect;
exit;
sub Tbody {

	my $Tbody = $_[0];
	$#Txn = -1;
#  Extract the first row

	$Tbody =~ /^.*?(<tr.*?>.*?<\/tr>)(.*)$/i;

	$First_row = $1;
	$Rest = $2;

	$First_row =~ s/^.*?(<tr.*?>.*?<\/tr>)/&First_Row($1)/ei;
	@First_row = split(/\t/,$First_row);
	if ($First_row[0] !~ /Contra/i) {
		$CFdate = $First_row[0];
		$No_txns++;
	}

	$FORM{txnamount} = $First_row[2];
	$FORM{txnamount} =~ tr/-//d;

	$Rest =~ s/^.*?<tbody>.*?(<tr.*?>.*<\/tr>)/$1/i;
	while ($Rest =~ s/(<tr.*?>.*?<\/tr>)/&Cell($1)/eig) {}
	$First_entry = '1';
	foreach (@Txn) {
		@Cells = split(/\t/,$_);

		$Cells[7] =~ tr/-//d;
		$Cells[8] =~ tr/-//d;

		if ($Cells[1] =~ /txn/i) {

#  This is easy, just add the txn id to the txn_ids list

			$Txn_ids .= $Cells[0].",";
		}
		else {

			$FORM{id} = $Cells[0];
			$FORM{invprintdate} = $Cells[2];
			$FORM{vatrate} = $Cells[3];
			$FORM{invcoa} = $Cells[4];
			$FORM{invcusname} = $Cells[5];
			$FORM{invdesc} = $Cells[6];
			$FORM{invitems} = '';
			$FORM{invtotal} = $Cells[7] - $Cells[8];
			$FORM{invvat} = $Cells[8];
			$FORM{invcusregion} = "UK";

			if ($Cells[1] =~ /new inv/i) {
				$FORM{id} = '';
				$FORM{cus_id} = $Cells[0];
				$FORM{invtype} = 'S';
				&save_invoice('final');
			}
			elsif ($Cells[1] =~ /new pur/i) {
				$FORM{id} = '';
				$FORM{cus_id} = $Cells[0];
				$FORM{invtype} = 'P';
				&save_purchase();
			}
			elsif ($Cells[1] =~ /intr/i) {

#  Get the next txn no

				my $Companies = $dbh->prepare("select comnexttxn from companies where reg_id=$Reg_id and id=$Com_id");
				$Companies->execute;
				my @Company = $Companies->fetchrow;
				$Companies->finish;

				$FORM{txnno} = $Company[0];
				$Sts = $dbh->do("update companies set comnexttxn=comnexttxn+1 where reg_id=$Reg_id and id=$Com_id");

#  Create a dummy invoice

				 $Sts = $dbh->do("insert into invoices (acct_id,invinvoiceno,invdesc,invcusregion,invcoa,invtotal,invpaid,invprintdate,invstatus,invstatuscode,invtype) values ('$COOKIE->{ACCT}','unlisted','Bank Interest','UK','4310','$FORM{invtotal}','$FORM{invtotal}',str_to_date('$FORM{invprintdate}','%d-%b-%y'),'Bank','2','BI')");
        			my $New_inv_id = $dbh->last_insert_id(undef, undef, qw(invoices undef));

#  Create the transaction

				$Sts = $dbh->do("insert into transactions (acct_id,txncusname,link_id,txnmethod,txnamount,txndate,txntxntype,txnremarks,txntxnno) values ('$COOKIE->{ACCT}','Bank Payment',$FORM{id},'$FORM{txnmethod}','$FORM{invtotal}',str_to_date('$FORM{invprintdate}','%d-%b-%y'),'bankint','Interest','$FORM{txnno}')");
				my $New_txn_id = $dbh->last_insert_id(undef, undef, qw(transactions undef));
				$Txn_ids .= $New_txn_id.",";

#  ... and the inv_txn record

				$Sts = $dbh->do("insert into inv_txns (acct_id,txn_id,inv_id,itnet,itvat,itdate,itmethod,itinvoiceno,ittxnno) values ('$COOKIE->{ACCT}',$New_txn_id,$New_inv_id,'$FORM{invtotal}','0',str_to_date('$FORM{invprintdate}','%d-%b-%y'),'$FORM{txnmethod}','unlisted','$FORM{txnno}')");

#  Update the account and 4310 coas

				$Sts = $dbh->do("update coas set coabalance=coabalance + '$FORM{invtotal}' where acct_id='$COOKIE->{ACCT}' and coanominalcode='$FORM{txnmethod}'");
				$Sts = $dbh->do("insert into nominals (acct_id,link_id,nomtype,nomcode,nomamount,nomdate) values ('$COOKIE->{ACCT}',$New_txn_id,'T','$FORM{txnmethod}','$FORM{invtotal}',str_to_date('$FORM{invprintdate}','%d-%b-%y'))");


				$Sts = $dbh->do("update coas set coabalance=coabalance + '$FORM{invtotal}' where acct_id='$COOKIE->{ACCT}' and coanominalcode='4310'");
				$Sts = $dbh->do("insert into nominals (acct_id,link_id,nomtype,nomcode,nomamount,nomdate) values ('$COOKIE->{ACCT}',$New_txn_id,'T','4310','$FORM{invtotal}',str_to_date('$FORM{invprintdate}','%d-%b-%y'))");

			}
			elsif ($Cells[1] =~ /chrgs/i) {

#  Get the next txn no

				my $Companies = $dbh->prepare("select comnexttxn from companies where reg_id=$Reg_id and id=$Com_id");
				$Companies->execute;
				my @Company = $Companies->fetchrow;
				$Companies->finish;

				$FORM{txnno} = $Company[0];
				$Sts = $dbh->do("update companies set comnexttxn=comnexttxn+1 where reg_id=$Reg_id and id=$Com_id");

#  Create a dummy invoice
				$Sts = $dbh->do("insert into invoices (acct_id,invinvoiceno,invdesc,invcusregion,invcoa,invtotal,invpaid,invprintdate,invstatus,invstatuscode,invtype) values ('$COOKIE->{ACCT}','unlisted','Bank Charges','UK','6010','$FORM{invtotal}','$FORM{invtotal}',str_to_date('$FORM{invprintdate}','%d-%b-%y'),'Bank','2','BC')");
        			my $New_inv_id = $dbh->last_insert_id(undef, undef, qw(invoices undef));

				$Sts = $dbh->do("insert into transactions (acct_id,link_id,txncusname,txnmethod,txnamount,txndate,txntxntype,txnremarks,txntxnno) values ('$COOKIE->{ACCT}',$New_inv_id,'Bank Payment','$FORM{txnmethod}','$FORM{invtotal}',str_to_date('$FORM{invprintdate}','%d-%b-%y'),'bankexp','Charges','$FORM{txnno}')");
				$New_txn_id = $dbh->last_insert_id(undef, undef, qw(transactions undef));
				$Txn_ids .= $New_txn_id.",";


				$Sts = $dbh->do("insert into inv_txns (acct_id,txn_id,inv_id,itnet,itvat,itdate,itmethod,itinvoiceno,ittxnno) values ('$COOKIE->{ACCT}',$New_txn_id,$New_inv_id,'$FORM{invtotal}','0',str_to_date('$FORM{invprintdate}','%d-%b-%y'),'$FORM{txnmethod}','unlisted','$FORM{txnno}')");

				$Sts = $dbh->do("update coas set coabalance=coabalance - '$FORM{invtotal}' where acct_id='$COOKIE->{ACCT}' and coanominalcode='$FORM{txnmethod}'");
				$Sts = $dbh->do("insert into nominals (acct_id,link_id,nomtype,nomcode,nomamount,nomdate) values ('$COOKIE->{ACCT}',$New_txn_id,'T','$FORM{txnmethod}',0-'$FORM{invtotal}',str_to_date('$FORM{invprintdate}','%d-%b-%y'))");

				$Sts = $dbh->do("update coas set coabalance=coabalance + '$FORM{invtotal}' where acct_id='$COOKIE->{ACCT}' and coanominalcode='6010'");
				$Sts = $dbh->do("insert into nominals (acct_id,link_id,nomtype,nomcode,nomamount,nomdate) values ('$COOKIE->{ACCT}',$New_txn_id,'T','6010','$FORM{invtotal}',str_to_date('$FORM{invprintdate}','%d-%b-%y'))");

			}
			elsif ($Cells[1] =~ /vat/i) {

#  Get the relevant VAT return

  				my $Vats = $dbh->prepare("select perbox3,perbox4,perbox5,perquarter from vatreturns where acct_id='$COOKIE->{ACCT}' and id=$Cells[0]");
				$Vats->execute;
				my $Vat = $Vats->fetchrow_hashref;
				$Vats->finish;

				$FORM{invtotal} = 0 - $FORM{invtotal};

				if ($FORM{invtotal} > 0) {
				        $Vatpay = "Refund";
				        $Txndir = "vat";
				        $Txnaction = "received from";
				}
				else {
				        $Vatpay = "Payment";
				        $Txndir = "vat";
				        $Txnaction = "paid to";
				}
#
				$Companies = $dbh->prepare("select comnexttxn from companies where reg_id=$Reg_id and id=$Com_id");
				$Companies->execute;
				@Company = $Companies->fetchrow;
				$Companies->finish;

				$FORM{txnno} = $Company[0];
				$Sts = $dbh->do("update companies set comnexttxn=comnexttxn+1 where reg_id=$Reg_id and id=$Com_id");

#  create a transaction

				$Sts = $dbh->do("insert into transactions (acct_id,link_id,txncusname,txnmethod,txnamount,txndate,txntxntype,txnremarks,txntxnno) values ('$COOKIE->{ACCT}',$Cells[0],'VAT $Vatpay','1200','$FORM{invtotal}',str_to_date('$FORM{invprintdate}','%d-%b-%y'),'$Txndir','$FORM{invdesc}','$FORM{txnno}')");
				$New_txn_id = $dbh->last_insert_id(undef, undef, qw(transactions undef));
				$Txn_ids .= $New_txn_id.",";

#  update the bank coa

				$Sts = $dbh->do("update coas set coabalance=coabalance + '$FORM{invtotal}' where acct_id='$COOKIE->{ACCT}' and coanominalcode='1200'");
				$Sts = $dbh->do("insert into nominals (acct_id,link_id,nomtype,nomcode,nomamount,nomdate) values ('$COOKIE->{ACCT}',$New_txn_id,'T','1200','$FORM{invtotal}',str_to_date('$FORM{invprintdate}','%d-%b-%y'))");

#  update the VAT Output coa (what we owe)

				$Sts = $dbh->do("update coas set coabalance=coabalance - '$Vat->{perbox3}' where acct_id='$COOKIE->{ACCT}' and coanominalcode='2100'");
				$Sts = $dbh->do("insert into nominals (acct_id,link_id,nomtype,nomcode,nomamount,nomdate) values ('$COOKIE->{ACCT}',$New_txn_id,'T','2100',0-'$Vat->{perbox3}',str_to_date('$FORM{invprintdate}','%d-%b-%y'))");

#  update VAT Input coa (what we are owed)

				$Sts = $dbh->do("update coas set coabalance=coabalance - '$Vat->{perbox4}' where acct_id='$COOKIE->{ACCT}' and coanominalcode='1400'");
				$Sts = $dbh->do("insert into nominals (acct_id,link_id,nomtype,nomcode,nomamount,nomdate) values ('$COOKIE->{ACCT}',$New_txn_id,'T','1400',0-'$Vat->{perbox4}',str_to_date('$FORM{invprintdate}','%d-%b-%y'))");


				$Sts = $dbh->do("update vatreturns set perstatus='Paid', perstatusdate=now() where acct_id='$COOKIE->{ACCT}' and id=$Cells[0]");


				$Sts = $dbh->do("update companies set comvatcontrol=comvatcontrol + '$FORM{invtotal}' where reg_id=$Reg_id and id=$Com_id");
			}

			if ($Cells[1] =~ /inv/i) {
				if ($First_entry) {
					&money_in();
					$Txn_ids .= $New_txn_id.',';
					$First_entry = '';
				}
				&pay_invoice();
			}
			elsif ($Cells[1] =~ /pur/i) {
				if ($First_entry) {
					&money_out();
					$Txn_ids .= $New_txn_id.',';
					$First_entry = '';
				}
				&pay_purchase();
			}
		}
	}
}

sub First_Row {
	my $Cell = $_[0];
	$Cell =~ s/.*?<tr.*?>(.*)?<\/tr>/$1/i;
	$Cell =~ s/\s*<td.*?>\s*//ig;
	$Cell =~ s/\s*<\/td>\s*/\t/g;
	$Cell =~ s/\<span.*?<\/span>//i;

#  Get the txnamount

	return $Cell;

}
sub Cell {

	my $Cell = $_[0];
	$Cell =~ s/.*?<tr.*?>(.*)?<\/tr>/$1/i;
	$Cell =~ s/\s*<td.*?>\s*//ig;
	$Cell =~ s/\s*<\/td>\s*/\t/g;
	$Cell =~ s/<img.*?>//g;

	push(@Txn,$Cell);
	return '';
}
