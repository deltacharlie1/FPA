#!/usr/bin/perl

#  Script to dump one or more complete registration sets from the fpa db.  If there is a parameter then dump just that registration id, else dump the lot.

open(FILE,">fpadump.xml") || die "Cannot open file";
;
$Tabs = "\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t";
$Tab_count = 0;

use MIME::Base64;
use DBI;

$dbh = DBI->connect("DBI:mysql:fpa");

if ($ARGV[0]) {	 #  only a single registration required

	$Registrations = $dbh->prepare("select regemail,regpwd,regmemword,regcompanyname,reglastlogindate,regregdate,regrenewaldue,regvisitcount,regmenutype,regdefaultmenu,regcountstartdate,regmembership,regactive,regdefaultrows,regactivecode,regoptin,reg_id from registrations where reg_id=$ARGV[0]");
}
else {
	$Registrations = $dbh->prepare("select regemail,regpwd,regmemword,regcompanyname,reglastlogindate,regregdate,regrenewaldue,regvisitcount,regmenutype,regdefaultmenu,regcountstartdate,regmembership,regactive,regdefaultrows,regactivecode,regoptin,reg_id from registrations");
}
$Registrations->execute;
if ($Registrations->rows > 0) {

	while ($Registration = $Registrations->fetchrow_hashref) {

		print FILE "<Registraion>\n";
		$Tab_count++;
		print FILE substr($Tabs,0,$Tab_count)."<Registration Details>\n";
		$Tab_count++;
		foreach $Key (sort keys %$Registration) {
			unless ($Key =~ /reg_id/i) {
				$Tag = $Key;
#				$Tag =~ s/^reg//;
				print FILE substr($Tabs,0,$Tab_count)."<$Tag>$Registration->{$Key}</$Tag>\n" if $Registration->{$Key};
			}
		}
		$Tab_count--;
		print FILE substr($Tabs,0,$Tab_count)."</Registration Details>\n";

#  Company

		$Companies = $dbh->prepare("select comname,comregno,comaddress,compostcode,comtel,combusiness,comcontact,comemail,comyearend,comnextsi,comnextpi,comnextpr,comnexttxn,comvatscheme,comvatno,comvatcontrol,comvatduein,comvatqstart,comvatmsgdue,comnocheques,comyearendmsgdue,comyearendreminder,comcompleted,comacccompleted,comrecstats,compaystats,comoptin,comemailmsg,comstmtmsg,comfree,comno_ads,comrep_invs,comstmts,comuplds,compt_logo,comhmrc,comsuppt,id from companies where reg_id=$Registration->{reg_id}");
		$Companies->execute;

		print FILE substr($Tabs,0,$Tab_count)."<Company>\n";
		$Tab_count++;
		while ($Company = $Companies->fetchrow_hashref) {
			print FILE substr($Tabs,0,$Tab_count)."<Company Details>\n";
			$Tab_count++;
			foreach $Key (sort keys %$Company) {
				unless ($Key =~ /^id/i) {
					$Tag = $Key;
#					$Tag =~ s/^com//;
					print FILE substr($Tabs,0,$Tab_count)."<$Tag>$Company->{$Key}</$Tag>\n" if $Company->{$Key};
				}
			}
			$Tab_count--;
			print FILE substr($Tabs,0,$Tab_count)."</Company Details>\n";

			$Acct_id = "$Registration->{reg_id}+$Company->{id}";

#  COAs

			$COAs = $dbh->prepare("select coanominalcode,coadesc,coatype,coareport,coabalance from coas where acct_id='$Acct_id'");
			$COAs->execute;
			if ($COAs->rows > 0) {
				print FILE substr($Tabs,0,$Tab_count)."<COAs>\n";
				$Tab_count++;
				while ($COA = $COAs->fetchrow_hashref) {
					print FILE substr($Tabs,0,$Tab_count)."<COA Details>\n";
					$Tab_count++;
					foreach $Key (sort keys %$COA) {
						unless ($Key =~ /^id/i) {
							$Tag = $Key;
#							$Tag =~ s/^acc//;
							print FILE substr($Tabs,0,$Tab_count)."<$Tag>$COA->{$Key}</$Tag>\n" if $COA->{$Key};
						}
					}
					$Tab_count--;
					print FILE substr($Tabs,0,$Tab_count)."</COA Details>\n";
				}
				$Tab_count--;
				print FILE substr($Tabs,0,$Tab_count)."</COAs>\n";
			}

#  Accounts

			$Accounts = $dbh->prepare("select acctype,accshort,accname,accacctno,acctswift,id from accounts where acct_id='$Acct_id'");
			$Accounts->execute;
			print FILE substr($Tabs,0,$Tab_count)."<Accounts>\n";
			$Tab_count++;
			while ($Account = $Accounts->fetchrow_hashref) {
				print FILE substr($Tabs,0,$Tab_count)."<Account>\n";
				$Tab_count++;
				print FILE substr($Tabs,0,$Tab_count)."<Account Details>\n";
				$Tab_count++;
				foreach $Key (sort keys %$Account) {
					unless ($Key =~ /^id/i) {
						$Tag = $Key;
#						$Tag =~ s/^acc//;
						print FILE substr($Tabs,0,$Tab_count)."<$Tag>$Account->{$Key}</$Tag>\n" if $Account->{$Key};
					}
				}
				$Tab_count--;
				print FILE substr($Tabs,0,$Tab_count)."</Account Details>\n";

#  Statements

				$Statements = $dbh->prepare("select staopenbal,staclosebal,stastmtno,stanotxns,staopendate,staclosedate,starec_no from statements where acct_id='$Acct_id' and acc_id=$Account->{id} order by starec_no");
				$Statements->execute;
				if ($Statements->rows > 0) {
					print FILE substr($Tabs,0,$Tab_count)."<Statements>\n";
					$Tab_count++;
					while ($Statement = $Statements->fetchrow_hashref) {
						print FILE substr($Tabs,0,$Tab_count)."<Statement Details>\n";
						$Tab_count++;
						foreach $Key (sort keys %$Statement) {
							unless ($Key =~ /^(id|acc_id)/i) {
								$Tag = $Key;
#								$Tag =~ s/^sta//;
								print FILE substr($Tabs,0,$Tab_count)."<$Tag>$Statement->{$Key}</$Tag>\n" if $Statement->{$Key};
							}
						}
						$Tab_count--;
						print FILE substr($Tabs,0,$Tab_count)."</Statement Details>\n";

#  Statement Charges/Interest

	                                	$Transactions = $dbh->prepare("select starec_no,txntxnno,txnamount,txndate,txnbanked,txnselected,txncusname,txnremarks,txnyearend,txncreated,txnmethod,txntxntype from transactions left join statements on (statements.id=stmt_id) where transactions.acct_id='$Acct_id' and txnmethod='$Account->{acctype}' and txncusname like 'Bank Payment%' and starec_no='$Statement->{starec_no}' order by transactions.id");
						$Transactions->execute;
						if ($Transactions->rows > 0) {
							print FILE substr($Tabs,0,$Tab_count)."<Statement Transactions>\n";
							$Tab_count++;
	                                		while ($Transaction = $Transactions->fetchrow_hashref) {
			                                        print FILE substr($Tabs,0,$Tab_count)."<Statement Transaction Details>\n";
	                		                        $Tab_count++;
	                                		        foreach $Key (sort keys %$Transaction) {
	                                                		unless ($Key =~ /^(id|acc_id)/i) {
			                                                        $Tag = $Key;
#	                		                                        $Tag =~ s/^sta//;
#	                                		                        $Tag =~ s/^txn//;
	                                                		        print FILE substr($Tabs,0,$Tab_count)."<$Tag>$Transaction->{$Key}</$Tag>\n" if $Transaction->{$Key};
			                                                }
	                		                        }
	                                        		$Tab_count--;
	                                        		print FILE substr($Tabs,0,$Tab_count)."</Statement Transaction Details>\n";
							}
	                                       		$Tab_count--;
	                                       		print FILE substr($Tabs,0,$Tab_count)."</Statement Transactions>\n";
						}
					}
					$Tab_count--;
					print FILE substr($Tabs,0,$Tab_count)."</Statements>\n";
				}

#  Transfers

                                $Transactions = $dbh->prepare("select starec_no,txntxnno,txnamount,txndate,txnbanked,txnselected,txncusname,txnremarks,txnyearend,txncreated,txnmethod,txntxntype from transactions left join statements on (statements.id=stmt_id) where transactions.acct_id='$Acct_id' and txnmethod='$Account->{acctype}' and txntxntype='transfer' order by transactions.id");
                                $Transactions->execute;
				if ($Transactions->rows > 0) {
	                                print FILE substr($Tabs,0,$Tab_count)."<Account Transactions>\n";
	                                $Tab_count++;
	                                while ($Transaction = $Transactions->fetchrow_hashref) {
	                                        print FILE substr($Tabs,0,$Tab_count)."<Account Transaction Details>\n";
	                                        $Tab_count++;
	                                        foreach $Key (sort keys %$Transaction) {
	                                                unless ($Key =~ /^(id|acc_id)/i) {
	                                                        $Tag = $Key;
#	                                                        $Tag =~ s/^sta//;
#	                                                        $Tag =~ s/^txn//;
	                                                        print FILE substr($Tabs,0,$Tab_count)."<$Tag>$Transaction->{$Key}</$Tag>\n" if $Transaction->{$Key};
	                                                }
	                                        }
	                                        $Tab_count--;
	                                        print FILE substr($Tabs,0,$Tab_count)."</Account Transaction Details>\n";
	                                }
	                                $Tab_count--;
	                                print FILE substr($Tabs,0,$Tab_count)."</Account Transactions>\n";
				}
				$Tab_count--;
				print FILE substr($Tabs,0,$Tab_count)."</Account>\n";
			}
			$Tab_count--;
			print FILE substr($Tabs,0,$Tab_count)."</Accounts>\n";

#  Opening Balances

                        $Transactions = $dbh->prepare("select starec_no,txntxnno,txnamount,txndate,txnbanked,txnselected,txncusname,txnremarks,txnyearend,txncreated,txnmethod,txntxntype from transactions left join statements on (statements.id=stmt_id) where transactions.acct_id='$Acct_id' and txncusname like 'Opening Balance%' order by transactions.id");
                        $Transactions->execute;
                        print FILE substr($Tabs,0,$Tab_count)."<Opening Balances>\n";
                        $Tab_count++;
                        while ($Transaction = $Transactions->fetchrow_hashref) {
                                print FILE substr($Tabs,0,$Tab_count)."<Opening Balance Details>\n";
                                $Tab_count++;
                                foreach $Key (sort keys %$Transaction) {
                                        unless ($Key =~ /^(id|acc_id)/i) {
                                                $Tag = $Key;
#                                                $Tag =~ s/^sta//;
#                                                $Tag =~ s/^txn//;
                                                print FILE substr($Tabs,0,$Tab_count)."<$Tag>$Transaction->{$Key}</$Tag>\n" if $Transaction->{$Key};
                                        }
                                }
                                $Tab_count--;
                                print FILE substr($Tabs,0,$Tab_count)."</Opening Balance Details>\n";
                        }
                        $Tab_count--;
                        print FILE substr($Tabs,0,$Tab_count)."</Opening Balances>\n";

#  Customers

			$Customers = $dbh->prepare("select cusname,cusaddress,cuspostcode,cusregion,custel,cuscontact,cusemail,custerms,cusdefcoa,cusdefvatrate,cusbank,cussortcode,cusacctno,cuscredit,cuslimit,cusdefpaymethod,cussales,cussupplier,cusremarks,cusemailmsg,cusstmtmsg,cusnextstmtdate,id from customers where acct_id='$Acct_id' order by cusname");
			$Customers->execute;
			if ($Customers->rows > 0) {
				print FILE substr($Tabs,0,$Tab_count)."<Customers>\n";
				$Tab_count++;
        	       		while ($Customer = $Customers->fetchrow_hashref) {
					print FILE substr($Tabs,0,$Tab_count)."<Customer Details>\n";
					$Tab_count++;
               		        	foreach $Key (sort keys %$Customer) {
                               			unless ($Key =~ /^(id|acc_id)/i) {
	                                               $Tag = $Key;
#		                                       $Tag =~ s/^cus//;
                	               		        print FILE substr($Tabs,0,$Tab_count)."<$Tag>$Customer->{$Key}</$Tag>\n" if $Customer->{$Key};
                        	                }
       	                        	}
		                       	$Tab_count--;
		                       	print FILE substr($Tabs,0,$Tab_count)."</Customer Details>\n";

#  Customer Invoices

					$Invoices = $dbh->prepare("select invinvoiceno,invcusref,invtype,invcusname,invcusaddr,invcuspostcode,invcusregion,invcuscontact,invcusemail,invcusterms,invremarks,invcoa,invcreated,invprintdate,invduedate,invtotal,invvat,invpaid,invpaidvat,invpaiddate,invstatus,invstatuscode,invstatusdate,invfpflag,invitemcount,invitems,invdesc,invyearend,id from invoices where acct_id='$Acct_id' and cus_id=$Customer->{id} and invstatus<>'Draft' order by invinvoiceno");
					$Invoices->execute;
					if ($Invoices->rows > 0) {
						print FILE substr($Tabs,0,$Tab_count)."<Customer Invoices>\n";
						$Tab_count++;
						while ($Invoice = $Invoices->fetchrow_hashref) {
							print FILE substr($Tabs,0,$Tab_count)."<Customer Invoice Details>\n";
							$Tab_count++;
               		        			foreach $Key (sort keys %$Invoice) {
		                        	       		unless ($Key =~ /^(id|acc_id)/i) {
                		                	               $Tag = $Key;
#									$Tag =~ s/^inv//;
									if ($Key =~ /invitems/i) {
										$Invoice->{invitems} = encode_base64($Invoice->{invitems});
										$Tag = "64".$Tag;
									}
                	               		        		print FILE substr($Tabs,0,$Tab_count)."<$Tag>$Invoice->{$Key}</$Tag>\n" if $Invoice->{$Key};
		        	                                }
       	        			                }
	                       				$Tab_count--;
			                       		print FILE substr($Tabs,0,$Tab_count)."</Customer Invoice Details>\n";

#  Invoice Items

							$Items = $dbh->prepare("select itmtype,itmqty,itmnomcode,itmdesc,itmtotal,itmvat,itmvatrate,itmdate from items where acct_id='$Acct_id' and inv_id=$Invoice->{id}");
							$Items->execute;
							if ($Items->rows > 0) {
								print FILE substr($Tabs,0,$Tab_count)."<Invoice Items>\n";
								$Tab_count++;
								while ($Item = $Items->fetchrow_hashref) {
									print FILE substr($Tabs,0,$Tab_count)."<Invoice Item Details>\n";
									$Tab_count++;
	       	 	       		        			foreach $Key (sort keys %$Item) {
				                               			unless ($Key =~ /^(id|acc_id)/i) {
		                			                               $Tag = $Key;
#											$Tag =~ s/^inv//;
	        	                       			        		print FILE substr($Tabs,0,$Tab_count)."<$Tag>$Item->{$Key}</$Tag>\n" if $Item->{$Key};
				                                	        }
	       	        			    		        }
		                       					$Tab_count--;
				                	     	  	print FILE substr($Tabs,0,$Tab_count)."</Invoice Items Details>\n";
								}
								$Tab_count--;
								print FILE substr($Tabs,0,$Tab_count)."</Invoice Items>\n";
							}
						}
		                       		$Tab_count--;
			                       	print FILE substr($Tabs,0,$Tab_count)."</Customer Invoices>\n";
					}

#  transactions

                        	       	$Transactions = $dbh->prepare("select starec_no,txntxnno,txnamount,txndate,txnbanked,txnselected,txncusname,txnremarks,txnyearend,txncreated,txnmethod,txntxntype,transactions.id as id from transactions left join statements on (statements.id=stmt_id) where txntxntype in ('income','expense') and transactions.acct_id='$Acct_id' and link_id=$Customer->{id} order by transactions.id");
					$Transactions->execute;
					if ($Transactions->rows > 0) {
						print FILE substr($Tabs,0,$Tab_count)."<Customer Transactions>\n";
						$Tab_count++;
						while ($Transaction = $Transactions->fetchrow_hashref) {
							print FILE substr($Tabs,0,$Tab_count)."<Customer Transaction Details>\n";
							$Tab_count++;
               		        			foreach $Key (sort keys %$Transaction) {
		                               			unless ($Key =~ /^(id|acc_id)/i) {
	                		                               $Tag = $Key;
#       	                        		                $Tag =~ s/^txn//;
                	               		        		print FILE substr($Tabs,0,$Tab_count)."<$Tag>$Transaction->{$Key}</$Tag>\n" if $Transaction->{$Key};
		        	                                }
       	        			                }
	                       				$Tab_count--;
			                       		print FILE substr($Tabs,0,$Tab_count)."</Customer Transaction Details>\n";
							$Inv_txns = $dbh->prepare("select itinvoiceno,itnet,itvat,itdate from inv_txns where acct_id='$Acct_id' and txn_id=$Transaction->{id}");
							$Inv_txns->execute;
							if ($Inv_txns->rows > 0) {
								print FILE substr($Tabs,0,$Tab_count)."<Customer Transaction Invoices>\n";
								$Tab_count++;
								while ($Inv_txn = $Inv_txns->fetchrow_hashref) {
									print FILE substr($Tabs,0,$Tab_count)."<Customer Transaction Invoice Details>\n";
									$Tab_count++;
               		        					foreach $Key (sort keys %$Inv_txn) {
		                               					unless ($Key =~ /^(id|acc_id)/i) {
			                		                               $Tag = $Key;
#       	        		                		                $Tag =~ s/^txn//;
                	               				        		print FILE substr($Tabs,0,$Tab_count)."<$Tag>$Inv_txn->{$Key}</$Tag>\n" if $Inv_txn->{$Key};
		        	                        		        }
       	        			      			        }
	                       						$Tab_count--;
				                		       	print FILE substr($Tabs,0,$Tab_count)."</Customer Transaction Invoice Details>\n";
								}
		                       				$Tab_count--;
				                	       	print FILE substr($Tabs,0,$Tab_count)."</Customer Transaction Invoices>\n";
							}
						}
	                       			$Tab_count--;
		                       		print FILE substr($Tabs,0,$Tab_count)."</Customer Transactions>\n";
					}
				}
        	               	$Tab_count--;
                	       	print FILE substr($Tabs,0,$Tab_count)."</Customers>\n";

#  unassigned VAT Accruals

				if ($COOKIE->{VAT} =~ /S/i) {
                               		$Vataccruals = $dbh->prepare("select acrtotal,acrvat,acrtype,acrprintdate,acrnominalcode,invinvoiceno as acrtxn_no from vataccruals left join invoices on (invoices.id=acrtxn_id) where vataccruals.acct_id='$Acct_id' and (vr_id=0 or isnull(vr_id)) order by vataccruals.id");
				}
				else {
                	               	$Vataccruals = $dbh->prepare("select acrtotal,acrvat,acrtype,acrprintdate,acrnominalcode,ittxnno as acrtxn_no from vataccruals left join inv_txns on (inv_txns.id=acrtxn_id) where vataccruals.acct_id='$Acct_id' and (vr_id=0 or isnull(vr_id))  order by vataccruals.id");
				}
				$Vataccruals->execute;
				if ($Vataccruals->rows > 0) {
					print FILE substr($Tabs,0,$Tab_count)."<VAT Accruals>\n";
					$Tab_count++;
                       			while ($Vataccrual = $Vataccruals->fetchrow_hashref) {
						print FILE substr($Tabs,0,$Tab_count)."<VAT Accrual Details>\n";
						$Tab_count++;
                       			        foreach $Key (sort keys %$Vataccrual) {
                                	       		unless ($Key =~ /^(id|acc_id)/i) {
	                                	                $Tag = $Key;
#              	                                	        $Tag =~ s/^sta//;
#                      		                        	$Tag =~ s/^txn//;
	                                       		        print FILE substr($Tabs,0,$Tab_count)."<$Tag>$Vataccrual->{$Key}</$Tag>\n" if $Vataccrual->{$Key};
		                                        }
               		                        }
                        	       		$Tab_count--;
                               			print FILE substr($Tabs,0,$Tab_count)."</VAT Accrual Details>\n";
					}
        	                       	$Tab_count--;
                	               	print FILE substr($Tabs,0,$Tab_count)."</VAT Accruals>\n";
				}

#  VAT Returns

				$Vatreturns = $dbh->prepare("select perquarter,perstartdate,perenddate,perduedate,perstatus,perstatusdate,perbox1,perbox2,perbox3,perbox4,perbox5,perbox6,perbox7,perbox8,perbox9,percompleted,perfiled,id from vatreturns order by id");
				$Vatreturns->execute;
				print FILE substr($Tabs,0,$Tab_count)."<VAT Returns>\n";
				$Tab_count++;
				while ($Vatreturn = $Vatreturns->fetchrow_hashref) {
					print FILE substr($Tabs,0,$Tab_count)."<VAT Return>\n";
					$Tab_count++;
					print FILE substr($Tabs,0,$Tab_count)."<VAT Return Details>\n";
					$Tab_count++;
					foreach $Key (sort keys %$Vatreturn) {
						unless ($Key =~ /^(id|acc_id)/i) {
							$Tag = $Key;
#							$Tag =~ s/per//;
							print FILE substr($Tabs,0,$Tab_count)."<$Tag>$Vatreturn->{$Key}</$Tag>\n";
						}
					}
					$Tab_count--;
					print FILE substr($Tabs,0,$Tab_count)."</VAT Return Details>\n";

#  VAT Accruals

					if ($COOKIE->{VAT} =~ /S/i) {
		                               	$Vataccruals = $dbh->prepare("select acrtotal,acrvat,acrtype,acrprintdate,acrnominalcode,invinvoiceno as acrtxn_no from vataccruals left join invoices on (invoices.id=acrtxn_id) where vataccruals.acct_id='$Acct_id' and vr_id=$Vatreturn->{id} order by vataccruals.id");
					}
					else {
	                        	       	$Vataccruals = $dbh->prepare("select acrtotal,acrvat,acrtype,acrprintdate,acrnominalcode,ittxnno as acrtxn_no from vataccruals left join inv_txns on (inv_txns.id=acrtxn_id) where vataccruals.acct_id='$Acct_id' and vr_id=$Vatreturn->{id} order by vataccruals.id");
					}
					$Vataccruals->execute;
					if ($Vataccruals->rows > 0) {
						print FILE substr($Tabs,0,$Tab_count)."<VAT Accruals>\n";
						$Tab_count++;
                               			while ($Vataccrual = $Vataccruals->fetchrow_hashref) {
							print FILE substr($Tabs,0,$Tab_count)."<VAT Accrual Details>\n";
							$Tab_count++;
        	                       		        foreach $Key (sort keys %$Vataccrual) {
                	                               		unless ($Key =~ /^(id|acc_id)/i) {
		        	                                        $Tag = $Key;
#                	        	                                $Tag =~ s/^sta//;
#                              			                        $Tag =~ s/^txn//;
                                               			        print FILE substr($Tabs,0,$Tab_count)."<$Tag>$Vataccrual->{$Key}</$Tag>\n" if $Vataccrual->{$Key};
			                                        }
        	        	                        }
                	                       		$Tab_count--;
                        	               		print FILE substr($Tabs,0,$Tab_count)."</VAT Accrual Details>\n";
						}
                                       		$Tab_count--;
	                                       	print FILE substr($Tabs,0,$Tab_count)."</VAT Accruals>\n";
					}
  
#  VAT Payments/Refunds

                	               	$Transactions = $dbh->prepare("select starec_no,txntxnno,txnamount,txndate,txnbanked,txnselected,txncusname,txnremarks,txnyearend,txncreated,txnmethod,txntxntype from transactions left join statements on (statements.id=stmt_id) where transactions.acct_id='$Acct_id' and txntxntype='vat' and link_id=$Vatreturn->{id} order by transactions.id");
					$Transactions->execute;
					if ($Transactions->rows > 0) {
						print FILE substr($Tabs,0,$Tab_count)."<VAT Transaction Details>\n";
						$Tab_count++;
        	                       		while ($Transaction = $Transactions->fetchrow_hashref) {
                	               		        foreach $Key (sort keys %$Transaction) {
                        	                       		unless ($Key =~ /^(id|acc_id)/i) {
		                	                                $Tag = $Key;
#                	                	                        $Tag =~ s/^sta//;
#                              		        	                $Tag =~ s/^txn//;
                                               			        print FILE substr($Tabs,0,$Tab_count)."<$Tag>$Transaction->{$Key}</$Tag>\n" if $Transaction->{$Key};
			                                        }
        	        	                        }
						}
                        	               	$Tab_count--;
                                	       	print FILE substr($Tabs,0,$Tab_count)."</VAT Transaction Details>\n";
					}
					$Tab_count--;
					print FILE substr($Tabs,0,$Tab_count)."</VAT Return>\n";
				}
				$Tab_count--;
				print FILE substr($Tabs,0,$Tab_count)."<VAT Returns>\n";
			}
		}
		$Tab_count--;
		print FILE substr($Tabs,0,$Tab_count)."</Company>\n";
		
		$Tab_count--;
		print FILE "</Registraion>\n";
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
$dbh->disconnect;
close(FILE);
exit;
