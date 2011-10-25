#!/usr/bin/perl

#  Script to dump all customers, invoices, transactions and vat returns for an account 

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

$Companies = $dbh->prepare("select comname,comaddress,compostcode,comtel,combusiness,comcontact,comemail,comregno,reg_id,id,id as old_id from companies where id=$ARGV[0]");
$Companies->execute;
if ($Companies->rows > 0) {
	print FILE substr($Tabs,0,$Tab_count)."<Company>\n";
	$Tab_count++;
	while ($Company = $Companies->fetchrow_hashref) {

		print FILE substr($Tabs,0,$Tab_count)."<Company Details>\n";
		$Tab_count++;
		foreach $Key (sort keys %$Company) {
			$Tag = $Key;
			$Tag =~ s/^com//;
			$Company->{$Key} =~ s/\n/\\\\n/g;
			unless ($Tag =~ /id$/i) {
				print FILE substr($Tabs,0,$Tab_count)."<$Tag>$Company->{$Key}</$Tag>\n" if $Company->{$Key};
			}
		}
		$Tab_count--;
		print FILE substr($Tabs,0,$Tab_count)."</Company Details>\n";

#  Set up Acct_id

		$Acct_id = "$Company->{reg_id}+$Company->{id}";

#  Customers

		$Customers = $dbh->prepare("select cusname,cusaddress,cuspostcode,cusregion,custel,cuscontact,cusemail,custerms,cusdefcoa,cusdefvatrate,cusbank,cussortcode,cusacctno,id as old_id from customers where acct_id='$Acct_id' order by cusname");
		$Customers->execute;
		if ($Customers->rows > 0) {
			print FILE substr($Tabs,0,$Tab_count)."<Customers>\n";
			$Tab_count++;
       	       		while ($Customer = $Customers->fetchrow_hashref) {
				print FILE substr($Tabs,0,$Tab_count)."<Customer - $Customer->{cusname}>\n";
				$Tab_count++;
				print FILE substr($Tabs,0,$Tab_count)."<Customer Details>\n";
				$Tab_count++;
       		        	foreach $Key (sort keys %$Customer) {
					$Customer->{$Key} =~ tr/\r//d;
					$Customer->{$Key} =~ s/\n/\\n/g;
					$Tag = $Key;
					$Tag =~ s/^cus//;
					unless ($Tag =~ /id$/i) {
						print FILE substr($Tabs,0,$Tab_count)."<$Tag>$Customer->{$Key}</$Tag>\n" if $Customer->{$Key};
					}
				}
				$Tab_count--;
				print FILE substr($Tabs,0,$Tab_count)."</Customer Details>\n";

#  Customer Invoices

				$Invoices = $dbh->prepare("select cus_id,invinvoiceno,invcusname,invcusaddr,invcuspostcode,invcusregion,invcuscontact,invcusemail,invcusterms,invremarks,invourref,invcusref,invtype,invcoa,invcreated,invprintdate,invduedate,invtotal,invvat,invpaid,invpaidvat,invpaiddate,invstatus,invdesc,id as old_id from invoices where acct_id='$Acct_id' and invstatuscode>1 order by invinvoiceno");
				$Invoices->execute;
				if ($Invoices->rows > 0) {
					print FILE substr($Tabs,0,$Tab_count)."<Customer Invoices>\n";
					$Tab_count++;
					while ($Invoice = $Invoices->fetchrow_hashref) {
						print FILE substr($Tabs,0,$Tab_count)."<Invoice - $Invoice->{invinvoiceno}>\n";
						$Tab_count++;
						print FILE substr($Tabs,0,$Tab_count)."<Invoice Details>\n";
						$Tab_count++;
						foreach $Key (sort keys %$Invoice) {
							$Tag = $Key;
							$Tag =~ s/^inv//;
							$Invoice->{$Key} =~ tr/\r//d;
							$Invoice->{$Key} =~ s/\n/\\n/g;
							unless ($Tag =~ /id$/i) {
								print FILE substr($Tabs,0,$Tab_count)."<$Tag>$Invoice->{$Key}</$Tag>\n" if $Invoice->{$Key};
							}
						}
						$Tab_count--;
						print FILE substr($Tabs,0,$Tab_count)."</Invoice Details>\n";

#  Invoice Items

						$Items = $dbh->prepare("select itmtype,itmqty,itmnomcode,itmdesc,itmtotal,itmvat,itmvatrate,itmdate from items where acct_id='$Acct_id' and inv_id=$Invoice->{old_id} order by id");
						$Items->execute;
						if ($Items->rows > 0) {
							print FILE substr($Tabs,0,$Tab_count)."<Invoice Items>\n";
							$Tab_count++;
							while ($Item = $Items->fetchrow_hashref) {
								print FILE substr($Tabs,0,$Tab_count)."<Invoice Item Details>\n";
								$Tab_count++;
								foreach $Key (sort keys %$Item) {
									$Tag = $Key;
									$Tag =~ s/^inv//;
									unless ($Tag =~ /id$/i) {
										print FILE substr($Tabs,0,$Tab_count)."<$Tag>$Item->{$Key}</$Tag>\n" if $Item->{$Key};
									}
								}
								$Tab_count--;
								print FILE substr($Tabs,0,$Tab_count)."</Invoice Items Details>\n";
							}
							$Tab_count--;
							print FILE substr($Tabs,0,$Tab_count)."</Invoice Items>\n";
						}

#  Inv_txns

						$Inv_txns = $dbh->prepare("select txnamount,txndate,txnremarks,txnmethod,itnet,itvat,itdate,inv_txns.id as old_id from inv_txns left join transactions on (inv_txns.txn_id=transactions.id and inv_txns.acct_id=transactions.acct_id) where inv_txns.acct_id='$Acct_id' and inv_id=$Invoice->{old_id} order by inv_txns.id");
						$Inv_txns->execute;
						if ($Inv_txns-> rows > 0) {
							print FILE substr($Tabs,0,$Tab_count)."<Transactions>\n";
							$Tab_count++;
							while ($Inv_txn = $Inv_txns->fetchrow_hashref) {
								print FILE substr($Tabs,0,$Tab_count)."<Transaction Details>\n";
								$Tab_count++;
								foreach $Key (sort keys %$Inv_txn) {
									$Tag = $Key;
									$Tag =~ s/^sta//;
									$Tag =~ s/^txn//;
									unless ($Tag =~ /id$/i) {
										print FILE substr($Tabs,0,$Tab_count)."<$Tag>$Inv_txn->{$Key}</$Tag>\n" if $Inv_txn->{$Key};
									}
								}
								$Tab_count--;
								print FILE substr($Tabs,0,$Tab_count)."</Transaction Details>\n";
							}
							$Tab_count--;
							print FILE substr($Tabs,0,$Tab_count)."</Transactions>\n";
						}
						$Tab_count--;
						print FILE substr($Tabs,0,$Tab_count)."</Invoice - $Invoice->{invinvoiceno}>\n";
					}
					$Tab_count--;
					print FILE substr($Tabs,0,$Tab_count)."</Customer Invoices>\n";
				}
				$Tab_count--;
				print FILE substr($Tabs,0,$Tab_count)."</Customer - $Customer->{cusname}>\n";
			}
			$Tab_count--;
			print FILE substr($Tabs,0,$Tab_count)."</Customers>\n";
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
					$Tag =~ s/per//;
					unless ($Tag =~ /id$/i) {
						print FILE substr($Tabs,0,$Tab_count)."<$Tag>$Vatreturn->{$Key}</$Tag>\n";
					}
				}
				$Tab_count--;
				print FILE substr($Tabs,0,$Tab_count)."</VAT Return Details>\n";
			}
			$Tab_count--;
			print FILE substr($Tabs,0,$Tab_count)."</VAT Returns>\n";
		}
		$Tab_count--;
		print FILE substr($Tabs,0,$Tab_count)."</Company>\n";
	}
}
$Companies->finish;
$Vatreturns->finish;
$Customers->finish;
$Invoices->finish;
$Items->finish;
$Inv_txns->finish;
$dbh->disconnect;
close(FILE);
exit;
