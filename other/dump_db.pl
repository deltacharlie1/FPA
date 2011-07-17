#!/usr/bin/perl

#  Script to dump all details fro a particular company (identified by id)

unless ($ARGV[0] =~ /^\d+$/) {
	print "\nYou must enter the company id as a single numeric parameter\n\n\tSyntax is:-\t./dump_db.pl <companies id>\n\n";
	exit;
}

open(FILE,">fpadump.xml") || die "Cannot open file";
;
$Tabs = "\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t";
$Tab_count = 0;

use MIME::Base64;
use DBI;

$dbh = DBI->connect("DBI:mysql:fpa");

#  Get the Company details

$Companies = $dbh->prepare("select comname,comregno,comaddress,compostcode,comtel,combusiness,comcontact,comemail,comyearend,comnextsi,comnextpi,comnextpr,comnexttxn,comvatscheme,comvatno,comvatcontrol,comvatduein,comvatqstart,comvatmsgdue,comnocheques,comyearendmsgdue,comyearendreminder,comcompleted,comacccompleted,comoptin,comexpid,comemailmsg,comstmtmsg,comfree,comno_ads,comrep_invs,comstmts,comuplds,compt_logo,comhmrc,comsuppt,comadd_user,cominvstats,comtxnstats,comnetstats,comdocsdir,reg_id,id,id as old_id from companies where id=$ARGV[0]");
$Companies->execute;
if ($Companies->rows > 0) {
	print FILE substr($Tabs,0,$Tab_count)."<Company>\n";
	$Tab_count++;
	while ($Company = $Companies->fetchrow_hashref) {

#  First of all we need to get the main registration so that we gt the new id when we reload the account

		$Registrations = $dbh->prepare("select regemail,regpwd,regmemword,regcompanyname,reglastlogindate,regregdate,regrenewaldue,regvisitcount,regmenutype,regdefaultmenu,regcountstartdate,regmembership,regactive,regdefaultrows,regactivecode,regoptin,reg_id as old_id from registrations where reg_id=$Company->{reg_id}");
		$Registrations->execute;
		if ($Registrations->rows > 0) {
			print FILE substr($Tabs,0,$Tab_count)."<Main Registration>\n";
			$Tab_count++;
			while ($Registration = $Registrations->fetchrow_hashref) {
				print FILE substr($Tabs,0,$Tab_count)."<Registration Details>\n";
				$Tab_count++;
				foreach $Key (sort keys %$Registration) {
					$Tag = $Key;
#					$Tag =~ s/^reg//;
					print FILE substr($Tabs,0,$Tab_count)."<$Tag>$Registration->{$Key}</$Tag>\n" if $Registration->{$Key};
				}
				$Tab_count--;
				print FILE substr($Tabs,0,$Tab_count)."</Registration Details>\n";
			}
			$Tab_count--;
			print FILE substr($Tabs,0,$Tab_count)."</Main Registration>\n";
		}

		print FILE substr($Tabs,0,$Tab_count)."<Company Details>\n";
		$Tab_count++;
		foreach $Key (sort keys %$Company) {
			$Tag = $Key;
#			$Tag =~ s/^com//;
			$Company->{$Key} =~ s/\n/\\\\n/g;
			unless ($Tag =~ /^id$/i) {
				print FILE substr($Tabs,0,$Tab_count)."<$Tag>$Company->{$Key}</$Tag>\n" if $Company->{$Key};
			}
		}
		$Tab_count--;
		print FILE substr($Tabs,0,$Tab_count)."</Company Details>\n";

#  No do reg_coms for this company and, for each one, do registrations

		$Reg_coms = $dbh->prepare("select reg1_id,reg2_id,com_id,comname,id as old_id from reg_coms where com_id=$Company->{old_id}");
		$Reg_coms->execute;
		if ($Reg_coms->rows > 0) {
			print FILE substr($Tabs,0,$Tab_count)."<Reg Com>\n";
			$Tab_count++;
			while ($Reg_com = $Reg_coms->fetchrow_hashref) {
				print FILE substr($Tabs,0,$Tab_count)."<Reg Com Details>\n";
				$Tab_count++;
				foreach $Key (sort keys %$Reg_com) {
					$Tag = $Key;
#					$Tag =~ s/^com//;
					print FILE substr($Tabs,0,$Tab_count)."<$Tag>$Reg_com->{$Key}</$Tag>\n" if $Reg_com->{$Key};
				}
				$Tab_count--;
				print FILE substr($Tabs,0,$Tab_count)."</Reg Com Details>\n";

#  For each Reg Com, pull registration details

				$Registrations = $dbh->prepare("select regemail,regpwd,regmemword,regcompanyname,reglastlogindate,regregdate,regrenewaldue,regvisitcount,regmenutype,regdefaultmenu,regcountstartdate,regmembership,regactive,regdefaultrows,regactivecode,regoptin,reg_id as old_id from registrations where reg_id=$Reg_com->{reg1_id} and reg_id <> $Company->{reg_id}");
				$Registrations->execute;
				if ($Registrations->rows > 0) {
					print FILE substr($Tabs,0,$Tab_count)."<Registration>\n";
					$Tab_count++;
					while ($Registration = $Registrations->fetchrow_hashref) {
						print FILE substr($Tabs,0,$Tab_count)."<Registration Details>\n";
						$Tab_count++;
						foreach $Key (sort keys %$Registration) {
							$Tag = $Key;
#							$Tag =~ s/^reg//;
							print FILE substr($Tabs,0,$Tab_count)."<$Tag>$Registration->{$Key}</$Tag>\n" if $Registration->{$Key};
						}
						$Tab_count--;
						print FILE substr($Tabs,0,$Tab_count)."</Registration Details>\n";
					}
					$Tab_count--;
					print FILE substr($Tabs,0,$Tab_count)."</Registration>\n";
				}
			}
			$Tab_count--;
			print FILE substr($Tabs,0,$Tab_count)."</Reg Com>\n";
		}

#  Set up Acct_id

		$Acct_id = "$Company->{reg_id}+$Company->{id}";

#  COAs

		$COAs = $dbh->prepare("select coanominalcode,coadesc,coatype,coareport,coabalance,id as old_id from coas where acct_id='$Acct_id'");
		$COAs->execute;
		if ($COAs->rows > 0) {
			print FILE substr($Tabs,0,$Tab_count)."<COAs>\n";
			$Tab_count++;
			while ($COA = $COAs->fetchrow_hashref) {
				print FILE substr($Tabs,0,$Tab_count)."<COA Details>\n";
				$Tab_count++;
				foreach $Key (sort keys %$COA) {
					$Tag = $Key;
#					$Tag =~ s/^acc//;
					print FILE substr($Tabs,0,$Tab_count)."<$Tag>$COA->{$Key}</$Tag>\n" if $COA->{$Key};
				}
				$Tab_count--;
				print FILE substr($Tabs,0,$Tab_count)."</COA Details>\n";
			}
			$Tab_count--;
			print FILE substr($Tabs,0,$Tab_count)."</COAs>\n";
		}

#  Accounts

		$Accounts = $dbh->prepare("select acctype,accshort,accname,accacctno,acctswift,id as old_id from accounts where acct_id='$Acct_id'");
		$Accounts->execute;
		if ($Accounts->rows > 0) {
			print FILE substr($Tabs,0,$Tab_count)."<Accounts>\n";
			$Tab_count++;
			while ($Account = $Accounts->fetchrow_hashref) {
				print FILE substr($Tabs,0,$Tab_count)."<Account Details>\n";
				$Tab_count++;
				foreach $Key (sort keys %$Account) {
					$Tag = $Key;
#					$Tag =~ s/^acc//;
					print FILE substr($Tabs,0,$Tab_count)."<$Tag>$Account->{$Key}</$Tag>\n" if $Account->{$Key};
				}
				$Tab_count--;
				print FILE substr($Tabs,0,$Tab_count)."</Account Details>\n";
			}
			$Tab_count--;
			print FILE substr($Tabs,0,$Tab_count)."</Accounts>\n";
		}

#  Statements

		$Statements = $dbh->prepare("select staopenbal,staclosebal,stastmtno,stanotxns,staopendate,staclosedate,starec_no,acc_id,id as old_id from statements where acct_id='$Acct_id' order by starec_no");
		$Statements->execute;
		if ($Statements->rows > 0) {
			print FILE substr($Tabs,0,$Tab_count)."<Statements>\n";
			$Tab_count++;
			while ($Statement = $Statements->fetchrow_hashref) {
				print FILE substr($Tabs,0,$Tab_count)."<Statement Details>\n";
				$Tab_count++;
				foreach $Key (sort keys %$Statement) {
					$Tag = $Key;
#					$Tag =~ s/^sta//;
					print FILE substr($Tabs,0,$Tab_count)."<$Tag>$Statement->{$Key}</$Tag>\n" if $Statement->{$Key};
				}
				$Tab_count--;
				print FILE substr($Tabs,0,$Tab_count)."</Statement Details>\n";
			}
			$Tab_count--;
			print FILE substr($Tabs,0,$Tab_count)."</Statements>\n";
		}

#  VAT Returns

		$Vatreturns = $dbh->prepare("select perquarter,perstartdate,perenddate,perduedate,perstatus,perstatusdate,perbox1,perbox2,perbox3,perbox4,perbox5,perbox6,perbox7,perbox8,perbox9,percompleted,perfiled,id as old_id from vatreturns  where acct_id='$Acct_id' order by id");
		$Vatreturns->execute;
		if ($Vatreturns->rows > 0) {
			print FILE substr($Tabs,0,$Tab_count)."<VAT Returns>\n";
			$Tab_count++;
			while ($Vatreturn = $Vatreturns->fetchrow_hashref) {
				print FILE substr($Tabs,0,$Tab_count)."<VAT Return Details>\n";
				$Tab_count++;
				foreach $Key (sort keys %$Vatreturn) {
					$Tag = $Key;
#					$Tag =~ s/per//;
					print FILE substr($Tabs,0,$Tab_count)."<$Tag>$Vatreturn->{$Key}</$Tag>\n";
				}
				$Tab_count--;
				print FILE substr($Tabs,0,$Tab_count)."</VAT Return Details>\n";
			}
			$Tab_count--;
			print FILE substr($Tabs,0,$Tab_count)."</VAT Returns>\n";
		}

#  Customers

		$Customers = $dbh->prepare("select cusname,cusaddress,cuspostcode,cusregion,custel,cuscontact,cusemail,custerms,cusdefcoa,cusdefvatrate,cusbank,cussortcode,cusacctno,cuscredit,cuslimit,cusdefpaymethod,cussales,cussupplier,cusremarks,cusemailmsg,cusstmtmsg,id as old_id from customers where acct_id='$Acct_id' order by cusname");
		$Customers->execute;
		if ($Customers->rows > 0) {
			print FILE substr($Tabs,0,$Tab_count)."<Customers>\n";
			$Tab_count++;
       	       		while ($Customer = $Customers->fetchrow_hashref) {
				print FILE substr($Tabs,0,$Tab_count)."<Customer Details>\n";
				$Tab_count++;
       		        	foreach $Key (sort keys %$Customer) {
					$Customer->{$Key} =~ s/\n/\\\\n/g;
					$Tag = $Key;
#					$Tag =~ s/^cus//;
					print FILE substr($Tabs,0,$Tab_count)."<$Tag>$Customer->{$Key}</$Tag>\n" if $Customer->{$Key};
				}
				$Tab_count--;
				print FILE substr($Tabs,0,$Tab_count)."</Customer Details>\n";
			}
			$Tab_count--;
			print FILE substr($Tabs,0,$Tab_count)."</Customers>\n";
		}

#  Customer Invoices

		$Invoices = $dbh->prepare("select cus_id,invinvoiceno,invourref,invcusref,invtype,invcusname,invcusaddr,invcuspostcode,invcusregion,invcuscontact,invcusemail,invcusterms,invremarks,invcoa,invcreated,invprintdate,invduedate,invtotal,invvat,invpaid,invpaidvat,invpaiddate,invstatus,invstatuscode,invstatusdate,invfpflag,invitemcount,invitems,invdesc,invyearend,id as old_id from invoices where acct_id='$Acct_id' order by invinvoiceno");
		$Invoices->execute;
		if ($Invoices->rows > 0) {
			print FILE substr($Tabs,0,$Tab_count)."<Customer Invoices>\n";
			$Tab_count++;
			while ($Invoice = $Invoices->fetchrow_hashref) {
				print FILE substr($Tabs,0,$Tab_count)."<Customer Invoice Details>\n";
				$Tab_count++;
				foreach $Key (sort keys %$Invoice) {
					$Tag = $Key;
#					$Tag =~ s/^inv//;
					if ($Key =~ /invitems/i) {
						$Invoice->{invitems} = encode_base64($Invoice->{invitems});
						$Tag = "64".$Tag;
					}
					$Invoice->{$Key} =~ s/\n/\\\\n/g;
					print FILE substr($Tabs,0,$Tab_count)."<$Tag>$Invoice->{$Key}</$Tag>\n" if $Invoice->{$Key};
				}
				$Tab_count--;
				print FILE substr($Tabs,0,$Tab_count)."</Customer Invoice Details>\n";
			}
			$Tab_count--;
			print FILE substr($Tabs,0,$Tab_count)."</Customer Invoices>\n";
		}

#  Invoice Items

		$Items = $dbh->prepare("select itmtype,itmqty,itmnomcode,itmdesc,itmtotal,itmvat,itmvatrate,itmdate from items where acct_id='$Acct_id' order by id");
		$Items->execute;
		if ($Items->rows > 0) {
			print FILE substr($Tabs,0,$Tab_count)."<Invoice Items>\n";
			$Tab_count++;
			while ($Item = $Items->fetchrow_hashref) {
				print FILE substr($Tabs,0,$Tab_count)."<Invoice Item Details>\n";
				$Tab_count++;
				foreach $Key (sort keys %$Item) {
					$Tag = $Key;
#					$Tag =~ s/^inv//;
					print FILE substr($Tabs,0,$Tab_count)."<$Tag>$Item->{$Key}</$Tag>\n" if $Item->{$Key};
				}
				$Tab_count--;
				print FILE substr($Tabs,0,$Tab_count)."</Invoice Items Details>\n";
			}
			$Tab_count--;
			print FILE substr($Tabs,0,$Tab_count)."</Invoice Items>\n";
		}

#  Transactions

		$Transactions = $dbh->prepare("select link_id,stmt_id,txntxnno,txnamount,txndate,txnbanked,txnselected,txncusname,txnremarks,txnyearend,txncreated,txnmethod,txntxntype,id as old_id from transactions where transactions.acct_id='$Acct_id' order by transactions.id");
		$Transactions->execute;
		if ($Transactions->rows > 0) {
			print FILE substr($Tabs,0,$Tab_count)."<Transactions>\n";
			$Tab_count++;
			while ($Transaction = $Transactions->fetchrow_hashref) {
				print FILE substr($Tabs,0,$Tab_count)."<Transaction Details>\n";
				$Tab_count++;
				foreach $Key (sort keys %$Transaction) {
					$Tag = $Key;
#					$Tag =~ s/^sta//;
#					$Tag =~ s/^txn//;
					print FILE substr($Tabs,0,$Tab_count)."<$Tag>$Transaction->{$Key}</$Tag>\n" if $Transaction->{$Key};
				}
				$Tab_count--;
				print FILE substr($Tabs,0,$Tab_count)."</Transaction Details>\n";
			}
			$Tab_count--;
			print FILE substr($Tabs,0,$Tab_count)."</Transactions>\n";
		}

#  Inv_txns

		$Inv_txns = $dbh->prepare("select txn_id,inv_id,ittxnno,itinvoiceno,itnet,itvat,itdate,itmethod,id as old_id from inv_txns where acct_id='$Acct_id' order by id");
		$Inv_txns->execute;
		if ($Inv_txns-> rows > 0) {
			print FILE substr($Tabs,0,$Tab_count)."<Inv Txns>\n";
			$Tab_count++;
			while ($Inv_txn = $Inv_txns->fetchrow_hashref) {
				print FILE substr($Tabs,0,$Tab_count)."<Inv Txn Details>\n";
				$Tab_count++;
				foreach $Key (sort keys %$Inv_txn) {
					$Tag = $Key;
#					$Tag =~ s/^sta//;
#					$Tag =~ s/^txn//;
					print FILE substr($Tabs,0,$Tab_count)."<$Tag>$Inv_txn->{$Key}</$Tag>\n" if $Inv_txn->{$Key};
				}
				$Tab_count--;
				print FILE substr($Tabs,0,$Tab_count)."</Inv Txn Details>\n";
			}
			$Tab_count--;
			print FILE substr($Tabs,0,$Tab_count)."</Inv Txns>\n";
		}

#  Nominal Codes

		$Noms = $dbh->prepare("select link_id,nomtype,nomcode,nomamount,nomdate,id as old_id from nominals where acct_id='$Acct_id' order by id");
		$Noms->execute;
		if ($Noms-> rows > 0) {
			print FILE substr($Tabs,0,$Tab_count)."<Nominals>\n";
			$Tab_count++;
			while ($Nom = $Noms->fetchrow_hashref) {
				print FILE substr($Tabs,0,$Tab_count)."<Nominal Details>\n";
				$Tab_count++;
				foreach $Key (sort keys %$Nom) {
					$Tag = $Key;
#					$Tag =~ s/^sta//;
#					$Tag =~ s/^txn//;
					print FILE substr($Tabs,0,$Tab_count)."<$Tag>$Nom->{$Key}</$Tag>\n" if $Nom->{$Key};
				}
				$Tab_count--;
				print FILE substr($Tabs,0,$Tab_count)."</Nominal Details>\n";
			}
			$Tab_count--;
			print FILE substr($Tabs,0,$Tab_count)."</Nominals>\n";
		}

#  VAT Accruals

		$Vataccruals = $dbh->prepare("select vr_id,acrtotal,acrvat,acrtype,acrprintdate,acrquarter,acrnominalcode,acrtxn_id,id as old_id from vataccruals where acct_id='$Acct_id' order by id");
		$Vataccruals->execute;
		if ($Vataccruals->rows > 0) {
			print FILE substr($Tabs,0,$Tab_count)."<VAT Accruals>\n";
			$Tab_count++;
			while ($Vataccrual = $Vataccruals->fetchrow_hashref) {
				print FILE substr($Tabs,0,$Tab_count)."<VAT Accrual Details>\n";
				$Tab_count++;
				foreach $Key (sort keys %$Vataccrual) {
					$Tag = $Key;
#					$Tag =~ s/^sta//;
#					$Tag =~ s/^txn//;
					print FILE substr($Tabs,0,$Tab_count)."<$Tag>$Vataccrual->{$Key}</$Tag>\n" if $Vataccrual->{$Key};
				}
				$Tab_count--;
				print FILE substr($Tabs,0,$Tab_count)."</VAT Accrual Details>\n";
			}
			$Tab_count--;
			print FILE substr($Tabs,0,$Tab_count)."</VAT Accruals>\n";
		}

#  Audit Trails

		$Audits = $dbh->prepare("select link_id,audtype,audaction,audstamp,audtext,auduser from audit_trails where acct_id='$Acct_id' order by audstamp");
		$Audits->execute;
		if ($Audits->rows > 0) {
			print FILE substr($Tabs,0,$Tab_count)."<Audit Trails>\n";
			$Tab_count++;
			while ($Audit = $Audits->fetchrow_hashref) {
				print FILE substr($Tabs,0,$Tab_count)."<Audit Trail Details>\n";
				$Tab_count++;
				foreach $Key (sort keys %$Audit) {
					$Tag = $Key;
#					$Tag =~ s/^sta//;
#					$Tag =~ s/^txn//;
					print FILE substr($Tabs,0,$Tab_count)."<$Tag>$Audit->{$Key}</$Tag>\n" if $Audit->{$Key};
				}
				$Tab_count--;
				print FILE substr($Tabs,0,$Tab_count)."</Audit Trail Details>\n";
			}
			$Tab_count--;
			print FILE substr($Tabs,0,$Tab_count)."</Audit Trails>\n";
		}

#  Reminders

		$Reminders = $dbh->prepare("select remtext,remcode,remgrade,remstartdate,remenddate,id as old_id from reminders where acct_id='$Acct_id' order by id");
		$Reminders->execute;
		if ($Reminders->rows > 0) {
			print FILE substr($Tabs,0,$Tab_count)."<Reminders>\n";
			$Tab_count++;
			while ($Reminder = $Reminders->fetchrow_hashref) {
				print FILE substr($Tabs,0,$Tab_count)."<Reminder Details>\n";
				$Tab_count++;
				foreach $Key (sort keys %$Reminder) {
					$Reminder->{$Key} =~ s/\n/\\\\n/g;
					$Tag = $Key;
#					$Tag =~ s/^sta//;
#					$Tag =~ s/^txn//;
					print FILE substr($Tabs,0,$Tab_count)."<$Tag>$Reminder->{$Key}</$Tag>\n" if $Reminder->{$Key};
				}
				$Tab_count--;
				print FILE substr($Tabs,0,$Tab_count)."</Reminder Details>\n";
			}
			$Tab_count--;
			print FILE substr($Tabs,0,$Tab_count)."</Reminders>\n";
		}

# Temp Stacks 

		$Tss = $dbh->prepare("select caller,f1,f2,f3,f4,f5,f6,f7,f8,f9 from tempstacks where acct_id='$Acct_id' order by id");
		$Tss->execute;
		if ($Tss->rows > 0) {
			print FILE substr($Tabs,0,$Tab_count)."<Tempstacks>\n";
			$Tab_count++;
			while ($Ts = $Tss->fetchrow_hashref) {
				print FILE substr($Tabs,0,$Tab_count)."<Tempstack Details>\n";
				$Tab_count++;
				foreach $Key (sort keys %$Ts) {
					$Ts->{$Key} =~ s/\n/\\\\n/g;
					$Tag = $Key;
#					$Tag =~ s/^sta//;
#					$Tag =~ s/^txn//;
					print FILE substr($Tabs,0,$Tab_count)."<$Tag>$Ts->{$Key}</$Tag>\n" if $Ts->{$Key};
				}
				$Tab_count--;
				print FILE substr($Tabs,0,$Tab_count)."</Tempstack Details>\n";
			}
			$Tab_count--;
			print FILE substr($Tabs,0,$Tab_count)."</Tempstacks>\n";
		}
		$Tab_count--;
		print FILE substr($Tabs,0,$Tab_count)."</Company>\n";
	}
}
$Registrations->finish;
$Companies->finish;
$COAs->finish;
$Accounts->finish;
$Statements->finish;
$Vatreturns->finish;
$Vataccruals->finish;
$Transactions->finish;
$Customers->finish;
$Invoices->finish;
$Items->finish;
$Inv_txns->finish;
$Noms->finish;
$Audits->finish;
$Reminders->finish;
$Tss->finish;
$dbh->disconnect;
close(FILE);
exit;
