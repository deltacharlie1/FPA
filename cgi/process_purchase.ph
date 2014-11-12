sub get_com_details {

#  Get the VAT scheme and when due

        ($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});
       	$Companies = $dbh->prepare("select comvatscheme,comvatduein,date_format(curdate(),'%m'),comnextsi,comnextpi,comnexttxn from companies where reg_id=$Reg_id and id=$Com_id");
        $Companies->execute;
       	@Company = $Companies->fetchrow;
        $Companies->finish;
}

sub validate_customer {

#  Is this an existing customer?

	if ($FORM{cus_id} > 0) {

#  Set the customer/supplier flag

		$Sts = $dbh->do("update customers set $Custype='Y' where id=$FORM{cus_id} and acct_id='$COOKIE->{ACCT}'");
	}
	else {

#  First get the 'Unlisted' customer id (if it exists)

		$Customers = $dbh->prepare("select id from customers where cusname='Unlisted' and acct_id='$COOKIE->{ACCT}'");
		$Customers->execute;
		if ($Customers->rows > 0) {
#  Get the id
			($FORM{cus_id}) = $Customers->fetchrow;
			$Sts = $dbh->do("update customers set $Custype='Y' where id=$FORM{cus_id} and acct_id='$COOKIE->{ACCT}'");
		}
		else {
#  Create new unlisted customer
			$Sts = $dbh->do("insert into customers (acct_id,cusname,$Custype) values ('$COOKIE->{ACCT}','Unlisted','Y')");
#  ... and get the id
			$FORM{cus_id} = $dbh->last_insert_id(undef, undef, qw(customers undef));
		}
		$Customers->finish;
	}
}

sub process_pur_vat {

#  Ignore if not registered for VAT

        return if ($COOKIE->{VAT} =~ /N/i);

#  If Fixed Rate Scheme add VAT to net value

	if ($COOKIE->{VAT} =~ /F/i && ($FORM{invcoa} !~ /^10/ || ($FORM{invcoa} =~ /^10/  && ($FORM{invtotal} + $FORM{invvat}) < 2000))) {
		$FORM{invtotal} += $FORM{invvat};
		$FORM{invvat} = '0.00';
		return;
	}

#  Otherwise do any VAT

	my $Scheme = shift;
	my $Link_id = shift;

	if ($Scheme =~ /S/i) {			#  Purchase invoice raised

#  Add amount to VAT Input coa (1400)

		if ($FORM{invvat}) {
			$Sts = $dbh->do("update coas set coabalance=coabalance + '$FORM{invvat}' where coanominalcode='1400' and acct_id='$COOKIE->{ACCT}'");
			$Sts = $dbh->do("insert into nominals (acct_id,link_id,nomtype,nomcode,nomamount,nomdate) values ('$COOKIE->{ACCT}',$Link_id,'S','1400','$FORM{invvat}',str_to_date('$FORM{invprintdate}','%d-%b-%y'))");
		}

		if ($COOKIE->{VAT} =~ /S/i) {

#  deduct amount from VAT Control in companies

                	($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});
        	        $Sts = $dbh->do("update companies set comvatcontrol=comvatcontrol - '$FORM{invvat}' where reg_id=$Reg_id and id=$Com_id");
			my $Vatamt = 0 - $FORM{invvat};
			my $Netamt = 0 - $FORM{invtotal};

			$Sts = $dbh->do("insert into vataccruals (acct_id,acrtype,acrtotal,acrvat,acrprintdate,acrnominalcode,acrtxn_id) values ('$COOKIE->{ACCT}','P','$Netamt','$Vatamt',str_to_date('$FORM{invprintdate}','%d-%b-%y'),'$FORM{invcoa}',$Link_id)");
		}
	}
	elsif ($Scheme =~ /C/i && $COOKIE->{VAT} =~ /C/i) {

#  then update the VAT Input and accruals in the normal way

       	        ($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});
               	$Sts = $dbh->do("update companies set comvatcontrol=comvatcontrol - '$FORM{invvat}' where reg_id=$Reg_id and id=$Com_id");
		my $Vatamt = 0 - $FORM{invvat};
		my $Netamt = 0 - $FORM{invtotal};
		$Sts = $dbh->do("insert into vataccruals (acct_id,acrtype,acrtotal,acrvat,acrprintdate,acrnominalcode,acrtxn_id) values ('$COOKIE->{ACCT}','P','$Netamt','$Vatamt',str_to_date('$FORM{invprintdate}','%d-%b-%y'),'$FORM{invcoa}',$Link_id)");
	}
}

sub save_purchase {

	my $Level = shift;		#  Is this a draft or final invoice?

	if ($FORM{invtype} =~ /R/i) {

		$Custype = "cussupplier";
		$Invoice_type = "Refund";

#  Revese the sign of all amounts

                $FORM{invtotal} = 0 - $FORM{invtotal};
                $FORM{invvat} = 0 - $FORM{invvat};
                $FORM{txnamount} = 0 - $FORM{txnamount};
	}
	else {
		$Custype = "cussupplier";
		$Invoice_type = "Purchase Invoice";
	}

#  Set up invtotal if empty

	if ($FORM{txnamount} && ! $FORM{invtotal}) {
		$FORM{invtotal} = $FORM{txnamount} - $FORM{invvat};
	}
	if ($FORM{invtotal} && ! $FORM{txnamount}) {
		$FORM{txnamount} = $FORM{invtotal} + $FORM{invvat};
	}

	my $Totamt = 0 - $FORM{invtotal};
	my $Vatamt = 0 - $FORM{invvat};
	my $Txnamt = 0 - $FORM{txnamount};

#  Set up the invdesc if empty

	if ($FORM{invitems} && !$FORM{invdesc}) {
        	$FORM{invdesc} = $FORM{invitems};
        	$FORM{invdesc} =~ s/^.*?\<td.*?>(.*?)<\/td>.*$/$1/is;          #  Extract the first column of the first row for description
	}

#  Set up invitems if empty

	if ($FORM{invdesc} && ! $FORM{invitems}) {
	        my $Vatrate = $FORM{vatrate} * 100;
	        $Vatrate .= "%";

        	my $Net = sprintf("%1.2f",$FORM{invtotal});
	        my $Vat = sprintf("%1.2f",$FORM{invvat});
        	my $Tot = sprintf("%1.2f",$FORM{txnamount});

		$Net =~ tr/-//d;
		$Vat =~ tr/-//d;
		$Tot =~ tr/-//d;

		$FORM{invitemcount} = "1";
		if ($COOKIE->{VAT} =~ /N/i) {
	                $FORM{invitems} = sprintf<<EOD;
<table id="itemstable" class="items" border="0" cellpadding="0" cellspacing="0" width="610">
    <tr>
      <th width="350">Description</th>
      <th style="text-align: right;" width="50">Unit<br>Price</th>
      <th style="text-align: right;" width="30">Qty</th>
      <th style="text-align: right;" width="50">Sub<br>Total</th>
      <th style="text-align: right;" width="60">Total</th>
      <th style="display:none;"></th>
    </tr>
  <tr>
    <td>$FORM{invdesc}</td>
    <td class="txtright">$Net</td>
    <td class="txtright">1</td>
    <td class="txtright">$Net</td>
    <td class="txtright">$Net</td>
    <td class="hidden">$FORM{item_cat}</td>
  </tr>
</table>
EOD
		}
		else {
        	        $FORM{invitems} = sprintf<<EOD;
<table id="itemstable" class="items" border="0" cellpadding="0" cellspacing="0" width="610">
  <tbody>
    <tr>
      <th width="280">Description</th>
      <th style="text-align: right;" width="50">Unit<br>Price</th>
      <th style="text-align: right;" width="30">Qty</th>
      <th style="text-align: right;" width="50">Sub<br>Total</th>
      <th style="text-align: center;" width="30">VAT<br>Rate</th>
      <th style="text-align: right;" width="40">VAT<br>Amt</th>
      <th style="text-align: right;" width="60">Total</th>
      <th style="display:none;"></th>
    </tr>
  </tbody>
  <tr>
    <td>$FORM{invdesc}</td>
    <td class="txtright">$Net</td>
    <td class="txtright">1</td>
    <td class="txtright">$Net</td>
    <td class="txtcenter">$Vatrate</td>
    <td class="txtright">$Vat</td>
    <td class="txtright">$Tot</td>
    <td class="hidden">$FORM{item_cat}</td>
  </tr>
</table>
EOD
		}
	}

#  Make sure that we have a valid customer id

	&validate_customer();

#  Next deal with the invoice, itself

#  strip out the amend/delete buttons from line items

        $FORM{invitems} =~ tr/ //s;             #  squash multiple spaces

#  strip out the amend/delete buttons from line items

         $FORM{invitems} =~ tr/ //s;             #  squash multiple spaces

#  remove the Edit header column

         $FORM{invitems} =~ s/<th.*?Edit<\/th>//im;
         $FORM{invitems} =~ tr/\r//d;                    #  Remove all carriage returns
         $FORM{invitems} =~ s/(<td.*?>.*?<\/td>)/&Convert_Cols($1)/eigs; #  Convert embedded newlines to <br/>s
         $FORM{invitems} =~ s/<\/td><br\/>/<\/td>/gis;           #  remove pesky brs after col end tags

#  Remove the Edit buttons td

         while ($FORM{invitems} =~ s/<td.*?src=.*?\/td>//gim) {}

#  We now (should have) the html line items without the edit buttons or header


#  We assume that all Purchase Invoices are saved in a final state

	if ($FORM{id}) {		#  existing invoice
		$sts = $dbh->do("update invoices set invcusref='$FORM{invcusref}',invtype='$FORM{invtype}',invcusname='$FORM{invcusname}',invcusaddr='$FORM{invcusaddr}',invcuspostcode='$FORM{invcuspostcode}',invcusregion='$FORM{invcusregion}',invcoa='$FORM{invcoa}',invcuscontact='$FORM{invcuscontact}',invcusemail='$FORM{invcusemail}',invcusterms='$FORM{invcusterms}',invremarks='$FORM{invremarks}',invfpflag='$FORM{invfpflag}',invitemcount=$FORM{invitemcount},invitems='$FORM{invitems}',invdesc='$FORM{invdesc}',invtotal='$Totamt',invvat='$Vatamt',invstatus='printed',invstatuscode='3',invprintdate=str_to_date('$FORM{invprintdate}','%d-%b-%y'),invyearend='$COOKIE->{YEAREND}' where id=$FORM{id} and acct_id='$COOKIE->{ACCT}'");
	}
	else {				#  New invoice so get the next invoice no
		&get_com_details();
		$FORM{invinvoiceno} = $Company[4];
		$Sts = $dbh->do("update companies set comnextpi=comnextpi+1 where reg_id=$Reg_id and id=$Com_id");

		$Sts = $dbh->do("insert into invoices (acct_id,cus_id,invinvoiceno,invcusref,invtype,invcusname,invcusaddr,invcuspostcode,invcusregion,invcoa,invcuscontact,invcusemail,invcusterms,invremarks,invcreated,invstatus,invstatuscode,invstatusdate,invfpflag,invitemcount,invitems,invdesc,invtotal,invvat,invprintdate,invyearend) values ('$COOKIE->{ACCT}',$FORM{cus_id},'$FORM{invinvoiceno}','$FORM{invcusref}','$FORM{invtype}','$FORM{invcusname}','$FORM{invcusaddr}','$FORM{invcuspostcode}','$FORM{invcusregion}','$FORM{invcoa}','$FORM{invcuscontact}','$FORM{invcusemail}','$FORM{invcusterms}','$FORM{invremarks}',now(),'Printed','3',now(),'$FORM{invfpflag}',$FORM{invitemcount},'$FORM{invitems}','$FORM{invdesc}','$Totamt','$Vatamt',str_to_date('$FORM{invprintdate}','%d-%b-%y'),'$COOKIE->{YEAREND}')");
		$FORM{id} = $dbh->last_insert_id(undef, undef, qw(invoices undef));

#  Separate and store the line item details

#  Dump the first (header) line

                $FORM{invitems} =~ s/^.*<\/th>.*?<\/tr>//is;

                $FORM{invitems} =~ tr/\r\n//d;                        #  remove any newlines
                $FORM{invitems} =~ s/<tbody.*?>//ig;                  #  Remove any additional tbody tags
                $FORM{invitems} =~ s/<\/tbody>//ig;
                $FORM{invitems} =~ s/<\/table>//ig;		      #  Remove table end tag
                $FORM{invitems} =~ s/<tr.*?>//gis;

                @Row = split(/\<\/tr\>/,$FORM{invitems});
                for $Row (@Row) {
                        $Row =~ s/<td.*?>//gis;
                        @Cell = split(/\<\/td\>/,$Row);

                        if ($Cell[1]) {         #  ie make sure we don't pick up the last (</table>) line

#  remove any date/increment brackets

			        $Cell[0] =~ s/\[(\%|\+|\-) //g;
			        $Cell[0] =~ s/ (\%|\+|\-)\]//g;

#  Convert ampersands

			        $Cell[0] =~ s/\&amp;/\&/ig;

                                $Cell[0] =~ s/^\s+//;

                                if ($COOKIE->{VAT} =~ /N/i) {
                                        $Sts = $dbh->do("insert into items (acct_id,inv_id,itmtype,itmqty,itmdesc,itmtotal,itmdate,itmcat) values ('$COOKIE->{ACCT}',$FORM{id},'P','$Cell[2]','$Cell[0]','$Cell[3]',str_to_date('$FORM{invprintdate}','%d-%b-%y'),'$Cell[5]')");
                                }
                                else {
                                        $Sts = $dbh->do("insert into items (acct_id,inv_id,itmtype,itmqty,itmdesc,itmtotal,itmvat,itmvatrate,itmdate,itmcat) values ('$COOKIE->{ACCT}',$FORM{id},'P','$Cell[2]','$Cell[0]','$Cell[3]','$Cell[5]','$Cell[4]',str_to_date('$FORM{invprintdate}','%d-%b-%y'),'$Cell[7]')");
                                }
                        }
                }
	}

#  Check to see whether we need to do the VAT

	&process_pur_vat('S',$FORM{id});

#  Update the customer balance

	$Sts = $dbh->do("update customers set cusbalance=cusbalance - '$FORM{txnamount}' where id=$FORM{cus_id} and acct_id='$COOKIE->{ACCT}'");

#  Add to the creditors control account

	$Sts = $dbh->do("update coas set coabalance=coabalance + '$FORM{txnamount}' where acct_id='$COOKIE->{ACCT}' and coanominalcode='2000'");
        $Sts = $dbh->do("insert into nominals (acct_id,link_id,nomtype,nomcode,nomamount,nomdate) values ('$COOKIE->{ACCT}',$FORM{id},'S','2000','$FORM{txnamount}',str_to_date('$FORM{invprintdate}','%d-%b-%y'))");


#  Add to the relevant expense account

	$Sts = $dbh->do("update coas set coabalance=coabalance + '$FORM{invtotal}' where acct_id='$COOKIE->{ACCT}' and coanominalcode='$FORM{invcoa}'");
        $Sts = $dbh->do("insert into nominals (acct_id,link_id,nomtype,nomcode,nomamount,nomdate) values ('$COOKIE->{ACCT}',$FORM{id},'S','$FORM{invcoa}','$FORM{invtotal}',str_to_date('$FORM{invprintdate}','%d-%b-%y'))");

	$Txnamt =~ tr/-//d;		#  remove any minus sign
	$Txnamt = sprintf("%1.2f",$Txnamt);

#  create audit trail record for the finalised invoice

	$Sts = $dbh->do("insert into audit_trails (acct_id,link_id,audtype,audaction,audtext,auduser) values ('$COOKIE->{ACCT}',$FORM{id},'update_purchase.pl','expense','$Invoice_type $FORM{invinvoiceno} for &pound;$Txnamt raised by $FORM{invcusname}','$COOKIE->{USER}')");
}

sub money_out {
#  Get the next transaction no

        &get_com_details();
        $FORM{txnno} = $Company[5];
        $Sts = $dbh->do("update companies set comnexttxn=comnexttxn+1 where reg_id=$Reg_id and id=$Com_id");

#  Set up txnamount if empty

	if ($FORM{invtotal} && ! $FORM{txnamount}) {
		$FORM{txnamount} = $FORM{invtotal} + $FORM{invvat};
	}

#  create a transaction record
	$Txntot = 0 - $FORM{txnamount};

	$Sts = $dbh->do("insert into transactions (acct_id,link_id,txncusname,txnmethod,txnamount,txndate,txntxntype,txnremarks,txnyearend,txntxnno) values ('$COOKIE->{ACCT}',$FORM{cus_id},'$FORM{invcusname}','$FORM{txnmethod}','$Txntot',str_to_date('$FORM{invprintdate}','%d-%b-%y'),'expense','$FORM{invdesc}','$COOKIE->{YEAREND}','$FORM{txnno}')");
	$New_txn_id = $dbh->last_insert_id(undef, undef, qw(transactions undef));

#  update nominal codes for bank/cash/cheque and customer unallocated balance

#  Bank, cash etc (adding a minus amount)

	if ($FORM{txnmethod} =~ /2010/) {
		$Sts = $dbh->do("update coas set coabalance=coabalance - '$Txntot' where acct_id='$COOKIE->{ACCT}' and coanominalcode='$FORM{txnmethod}'");
        	$Sts = $dbh->do("insert into nominals (acct_id,link_id,nomtype,nomcode,nomamount,nomdate) values ('$COOKIE->{ACCT}',$New_txn_id,'T','$FORM{txnmethod}',0-'$Txntot',str_to_date('$FORM{invprintdate}','%d-%b-%y'))");
	}
	else {
		$Sts = $dbh->do("update coas set coabalance=coabalance + '$Txntot' where acct_id='$COOKIE->{ACCT}' and coanominalcode='$FORM{txnmethod}'");
        	$Sts = $dbh->do("insert into nominals (acct_id,link_id,nomtype,nomcode,nomamount,nomdate) values ('$COOKIE->{ACCT}',$New_txn_id,'T','$FORM{txnmethod}','$Txntot',str_to_date('$FORM{invprintdate}','%d-%b-%y'))");
	}

#  Customer balance

	$Sts = $dbh->do("update customers set cusbalance=cusbalance - '$Txntot' where acct_id='$COOKIE->{ACCT}' and id=$FORM{cus_id}");

#  Creditor control acct  ('add' Txntot so that any sign is correct)

	$Sts = $dbh->do("update coas set coabalance=coabalance + '$Txntot' where acct_id='$COOKIE->{ACCT}' and coanominalcode='2000'");
        $Sts = $dbh->do("insert into nominals (acct_id,link_id,nomtype,nomcode,nomamount,nomdate) values ('$COOKIE->{ACCT}',$New_txn_id,'T','2000','$Txntot',str_to_date('$FORM{invprintdate}','%d-%b-%y'))");

	my $Tot = sprintf("%1.2f",$FORM{txnamount});
	$Tot =~ tr/-//d;
	$Sts = $dbh->do("insert into audit_trails (acct_id,link_id,audtype,audaction,audtext,auduser) values ('$COOKIE->{ACCT}',$New_txn_id,'transactions','expense','Made payment of &pound;$Tot to $FORM{invcusname}','$COOKIE->{USER}')");
}

sub pay_purchase {

#  get the current balance of the invoice

	my $Invoices = $dbh->prepare("select invstatuscode,invtotal,invvat,invpaid,invpaidvat,invtype,invinvoiceno,invcusname,invcoa from invoices where acct_id='$COOKIE->{ACCT}' and id=$FORM{id}");
	$Invoices->execute;
	my @Invoice = $Invoices->fetchrow;
	$Invoices->finish;

	if ($Invoices->rows > 0 && $Invoice[0] > 2) {		#  OK this is a good invoice

#  Revert the txnamount to a positive value (it may have been set negative by sub money_in)

		$FORM{txnamount} =~ tr/-//d;

#  then make sure that it is a negative amount

		$FORM{txnamount} = 0 - $FORM{txnamount};
		$FORM{txnamount} = sprintf('%1.2f',$FORM{txnamount});

		my $Owing = sprintf('%1.2f',$Invoice[1] + $Invoice[2] - $Invoice[3] - $Invoice[4]);

		$FORM{invtype} = $Invoice[5];
		$FORM{invinvoiceno} = $Invoice[6];
		$FORM{invcusname} = $Invoice[7];
		$FORM{invcoa} = $Invoice[8];
		$Invoice_type = "Purchase Invoice";

#  Compairon of non-integer numbers is failing so convert everything to pennies

		$P_txnamount = $FORM{txnamount};
		$P_Owing = $Owing;

		$P_txnamount =~ tr/\.//d;
		$P_Owing =~ tr/\.//d;

		if ($P_txnamount <= $P_Owing) {		#  sufficient funds to cover the
							#  (This way around because they are negative amounts)

#  Deduct what is owed from what we have to play with

			$FORM{txnamount} -= $Owing;
			$FORM{invtotal} = $Invoice[1] - $Invoice[3];
			$FORM{invvat} = $Invoice[2] - $Invoice[4];

#  Update invoice paid fields

			$Sts = $dbh->do("update invoices set invpaid=invtotal,invpaidvat=invvat,invstatus='Paid',invstatuscode='2',invstatusdate=now(),invpaiddate=str_to_date('$FORM{invprintdate}','%d-%b-%y') where acct_id='$COOKIE->{ACCT}' and id=$FORM{id}");

		}
		else {

#  Calculate the percentage of net and vat that can be paid

			$FORM{invvat} = sprintf("%1.2f",($Invoice[2] + $Invoice[4]) * $FORM{txnamount} / $Owing);

			$FORM{invtotal} = $FORM{txnamount} - $FORM{invvat};
			$Owing = $FORM{txnamount};

#  Update invoice paid fields

			$Sts = $dbh->do("update invoices set invpaid=invpaid + '$FORM{invtotal}',invpaidvat=invpaidvat + '$FORM{invvat}',invstatus='Part-Paid',invstatuscode='7',invstatusdate=now() where acct_id='$COOKIE->{ACCT}' and id=$FORM{id}");

		}

#  Create an inv_txn record

		$Sts = $dbh->do("insert into inv_txns (acct_id,txn_id,inv_id,itnet,itvat,itdate,itmethod,itinvoiceno,ittxnno) values ('$COOKIE->{ACCT}',$New_txn_id,$FORM{id},'$FORM{invtotal}','$FORM{invvat}',str_to_date('$FORM{invprintdate}''$FORM{txnmethod}','$Invoice[6]','$FORM{txnno}')");
		$New_inv_txn_id = $dbh->last_insert_id(undef, undef, qw(inv_txns undef));

#  deal with any VAT payments

		$FORM{invtotal} =~ tr/-//d;
		$FORM{invvat} =~ tr/-//d;

		&process_pur_vat('C',$New_inv_txn_id);

#  write an audit trail record

		$Owing =~ tr/-//d;
		$Owing = sprintf("%1.2f",$Owing);
		$Sts = $dbh->do("insert into audit_trails (acct_id,link_id,audtype,audaction,audtext,auduser) values ('$COOKIE->{ACCT}',$FORM{id},'update_purchase.pl','expense','&pound;$Owing allocated to $Invoice_type $Invoice[6] to make it fully Paid','$COOKIE->{USER}')");
	}
}
sub Convert_Cols {
        my $Col = shift;
        $Col =~ s/\n/<br\/>/g;
        return $Col;
}

1;
