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
	elsif ($FORM{cus_id} < 0) {

#  Tis is a new customer whose details are to be saved in customers

		$Sts = $dbh->do("insert into customers (acct_id,cusname,cusaddress,cuspostcode,cusregion,cuscontact,cusemail,custerms,cusdefpo,cussales) values ('$COOKIE->{ACCT}','$FORM{invcusname}','$FORM{invcusaddr}','$FORM{invcuspostcode}','$FORM{invcusregion}','$FORM{invcuscontact}','$FORM{invcusemail}','$FORM{invcusterms}','$FORM{invcusref}','Y')");
		$FORM{cus_id} = $dbh->last_insert_id(undef, undef, qw(customers undef));

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

sub process_vat {

#  Ignore if not registered for VAT

	return if ($COOKIE->{VAT} =~ /N/i);

#  Otherwise do any VAT

#  Scheme = S - means VAT processing for when an invoice is raised
#  Scheme = C - means VAT processing at time of transaction

#  At point of invoicing update VAT Output coa (2100) and, if Standard Accounting, update comvatcontrol
#  At point of transaction update comvatcontrol if Cash Accounting

	my $Scheme = shift;	#  Scheme = S or C
	my $Link_id = shift;	#  This is the invoice id

	my $Vatdue = $FORM{invvat}; 	#  get the VAT into a temporary variable (in case it is a FRS scheme)

	if ($COOKIE->{VAT} =~ /F/i) {

#  Calculate the reduced VAT.  VAT due = FRS percentage of GROSS value (ie invtotal + invvat)

		$Vatdue = sprintf("%1.2f",($FORM{invtotal} + $FORM{invvat}) * $COOKIE->{FRS});
	}
	if ($Scheme =~ /S/i) {		#  At point of invoicing

#  Update the VAT Output nominalcode

		if ($Vatdue) {
	
			$Sts = $dbh->do("update coas set coabalance=coabalance + '$Vatdue' where coanominalcode='2100' and acct_id='$COOKIE->{ACCT}'");
			$Sts = $dbh->do("insert into nominals (acct_id,link_id,nomtype,nomcode,nomamount,nomdate) values ('$COOKIE->{ACCT}',$Link_id,'S','2100','$Vatdue',str_to_date('$FORM{invprintdate}','%d-%b-%y'))");
		}

		if ($COOKIE->{VAT} =~ /S/i) {

#  Add amount to VAT Control in companies

        		($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});
			$Sts = $dbh->do("update companies set comvatcontrol=comvatcontrol + '$Vatdue' where reg_id=$Reg_id and id=$Com_id");

			$Sts = $dbh->do("insert into vataccruals (acct_id,acrtype,acrtotal,acrvat,acrprintdate,acrnominalcode,acrtxn_id) values ('$COOKIE->{ACCT}','S','$FORM{invtotal}','$Vatdue',str_to_date('$FORM{invprintdate}','%d-%b-%y'),'$FORM{invcoa}',$Link_id)");
		}
	}
	elsif ($Scheme =~ /C/i && $COOKIE->{VAT} =~ /C/i) {		#  At point of Paying

#  Add amount to VAT Control in companies

       		($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});
		$Sts = $dbh->do("update companies set comvatcontrol=comvatcontrol + '$Vatdue' where reg_id=$Reg_id and id=$Com_id");

		$Sts = $dbh->do("insert into vataccruals (acct_id,acrtype,acrtotal,acrvat,acrprintdate,acrnominalcode,acrtxn_id) values ('$COOKIE->{ACCT}','S','$FORM{invtotal}','$Vatdue',str_to_date('$FORM{invprintdate}','%d-%b-%y'),'$FORM{invcoa}',$Link_id)");
	}
}

sub save_invoice {

	my $Level = shift;		#  Is this a draft or final invoice?

	if ($FORM{invtype} =~ /S/i) {
		$Custype = "cussales";
		$Invoice_type = "Invoice";
	}
	else {
		$Custype = "cussales";
		$Invoice_type = "Credit Note";

#  and reverse the sign of all amounts

		$FORM{invtotal} = 0 - $FORM{invtotal};
		$FORM{invvat} = 0 - $FORM{invvat};
	}
#  Set up the Amd/Del buttons on the line items

	if ($FORM{invitems}) {
		$FORM{invitems} =~ s/value=\"?Amd\"?/value=\"Amd\" onclick=\"amd(this);\"/igs;
		$FORM{invitems} =~ s/value=\"?Del\"?/value=\"Del\" onclick=\"dlt(this);\"/igs;
	}

#  Set up the invdesc if empty

	if ($FORM{invitems} && ! $FORM{invdesc}) {
        	$FORM{invdesc} = $FORM{invitems};
        	$FORM{invdesc} =~ s/^.*?\<td.*?>(.*?)\<\/td>.*$/$1/is;          #  Extract the first column of the first row for description
	}

#  Set up invitems if empty

	if ($FORM{invdesc} && ! $FORM{invitems}) {
	        my $Vatrate = $FORM{vatrate} * 100;
	        $Vatrate .= "%";

        	my $Net = sprintf("%1.2f",$FORM{invtotal});
	        my $Vat = sprintf("%1.2f",$FORM{invvat});
        	my $Tot = sprintf("%1.2f",$FORM{txnamount});

		$FORM{invitemcount} = "1";
		if ($COOKIE->{VAT} =~ /N/i) {
	                $FORM{invitems} = sprintf<<EOD;
<table id="items" class="items" border="0" cellpadding="0" cellspacing="0" width="610">
  <tbody>
    <tr>
      <th width="350">Description</th>
      <th style="text-align: right;" width="50">Unit<br>Price</th>
      <th style="text-align: right;" width="30">Qty</th>
      <th style="text-align: right;" width="50">Sub<br>Total</th>
      <th style="text-align: right;" width="60">Total</th>
      <th style="display:none;"></th>
    </tr>
  </tbody>
  <tr>
    <td>$FORM{invdesc}</td><td class="txtright">$Net</td><td class="txtright">1</td><td class="txtright">$Net</td><td class="txtright">$Net</td><td class="hidden">$FORM{item_cat}</td>
  </tr>
</table>
EOD
		}
		else {
        	        $FORM{invitems} = sprintf<<EOD;
<table id="items" class="items" border="0" cellpadding="0" cellspacing="0" width="610">
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
    <td>$FORM{invdesc}</td><td class="txtright">$Net</td><td class="txtright">1</td><td class="txtright">$Net</td><td class="txtcenter">$Vatrate</td><td class="txtright">$Vat</td><td class="txtright">$Tot</td><td class="hidden">$FORM{item_cat}</td>
  </tr>
</table>
EOD
		}
	}

#  Make sure that we have a valid customer id

	&validate_customer();

#  Next deal with the invoice, itself

	if ($Level =~ /draft/i) {
		if ($FORM{id}) {		#  We are updating an existing invoice/credit note
			$Sts = $dbh->do("update invoices set invcusref='$FORM{invcusref}',invtype='$FORM{invtype}',invcusname='$FORM{invcusname}',invcusaddr='$FORM{invcusaddr}',invcuspostcode='$FORM{invcuspostcode}',invcusregion='$FORM{invcusregion}',invcoa='$FORM{invcoa}',invcuscontact='$FORM{invcuscontact}',invcusemail='$FORM{invcusemail}',invcusterms='$FORM{invcusterms}',invremarks='$FORM{invremarks}',invfpflag='$FORM{invfpflag}',invitemcount=$FORM{invitemcount},invitems='$FORM{invitems}',invdesc='$FORM{invdesc}',invtotal='$FORM{invtotal}',invvat='$FORM{invvat}' where id=$FORM{id} and acct_id='$COOKIE->{ACCT}'");
		}
		else {				#  this is a new invoice so get the next invoice no and then save details

			$Sts = $dbh->do("insert into invoices (acct_id,cus_id,invinvoiceno,invcusref,invtype,invcusname,invcusaddr,invcuspostcode,invcusregion,invcoa,invcuscontact,invcusemail,invcusterms,invremarks,invcreated,invstatus,invstatuscode,invstatusdate,invfpflag,invitemcount,invitems,invdesc,invtotal,invvat) values ('$COOKIE->{ACCT}',$FORM{cus_id},'$FORM{invinvoiceno}','$FORM{invcusref}','$FORM{invtype}','$FORM{invcusname}','$FORM{invcusaddr}','$FORM{invcuspostcode}','$FORM{invcusregion}','$FORM{invcoa}','$FORM{invcuscontact}','$FORM{invcusemail}','$FORM{invcusterms}','$FORM{invremarks}',now(),'Draft','1',now(),'$FORM{invfpflag}',$FORM{invitemcount},'$FORM{invitems}','$FORM{invdesc}','$FORM{invtotal}','$FORM{invvat}')");
			$FORM{id} = $dbh->last_insert_id(undef, undef, qw(invoices undef));
		}
	}
	else {					#  this is a finalised invoice so save additional fields and do additional processing

#  strip out the amend/delete buttons from line items

		$FORM{invitems} =~ tr/ //s;		#  squash multiple spaces

#  Sort out some IE inconsistences

		$FORM{invitems} =~ s/\<(\/?)TR(.*?)\>/<$1tr$2\>/g;
		$FORM{invitems} =~ s/\<(\/?)TD(.*?)\>/<$1td$2\>/g;
		$FORM{invitems} =~ s/(<td.*?>.+?)\n(.*?<td)/$1<br\/>$2/gis;	#  search for newline within <td ... /td>

		$FORM{invitems} =~ tr/\r\n//d;
	        $FORM{invitems} =~ s/\/td>/\/td>\n/gi;
	        $FORM{invitems} =~ s/\/th>/\/th>\n/gi;
	        $FORM{invitems} =~ s/<th.*?Edit<\/th>//im;
        	while ($FORM{invitems} =~ s/<td.*?input.*?\/td>//gim) {}

		&get_com_details();
		$FORM{invinvoiceno} = $Company[3];
		$Sts = $dbh->do("update companies set comnextsi=comnextsi+1 where reg_id=$Reg_id and id=$Com_id");

		if ($FORM{id}) {		#  existing invoice
			if ($FORM{invcusterms} =~ /^\d+$/) {	# we have some terms so include the due date

				$Sts = $dbh->do("update invoices set invinvoiceno='$Company[3]',invcusref='$FORM{invcusref}',invtype='$FORM{invtype}',invcusname='$FORM{invcusname}',invcusaddr='$FORM{invcusaddr}',invcuspostcode='$FORM{invcuspostcode}',invcusregion='$FORM{invcusregion}',invcoa='$FORM{invcoa}',invcuscontact='$FORM{invcuscontact}',invcusemail='$FORM{invcusemail}',invcusterms='$FORM{invcusterms}',invremarks='$FORM{invremarks}',invfpflag='$FORM{invfpflag}',invitemcount=$FORM{invitemcount},invitems='$FORM{invitems}',invdesc='$FORM{invdesc}',invtotal='$FORM{invtotal}',invvat='$FORM{invvat}',invstatus='Printed',invstatuscode='3',invprintdate=str_to_date('$FORM{invprintdate}','%d-%b-%y'),invduedate=from_days(to_days(str_to_date('$FORM{invprintdate}','%d-%b-%y')) + '$FORM{invcusterms}'),invyearend='$COOKIE->{YEAREND}' where id=$FORM{id} and acct_id='$COOKIE->{ACCT}'");
			}
			else {			#  no terms
				$Sts = $dbh->do("update invoices set invinvoiceno='$Company[3]',invcusref='$FORM{invcusref}',invtype='$FORM{invtype}',invcusname='$FORM{invcusname}',invcusaddr='$FORM{invcusaddr}',invcuspostcode='$FORM{invcuspostcode}',invcusregion='$FORM{invcusregion}',invcoa='$FORM{invcoa}',invcuscontact='$FORM{invcuscontact}',invcusemail='$FORM{invcusemail}',invcusterms='$FORM{invcusterms}',invremarks='$FORM{invremarks}',invfpflag='$FORM{invfpflag}',invitemcount=$FORM{invitemcount},invitems='$FORM{invitems}',invdesc='$FORM{invdesc}',invtotal='$FORM{invtotal}',invvat='$FORM{invvat}',invstatus='Printed',invstatuscode='3',invprintdate=str_to_date('$FORM{invprintdate}','%d-%b-%y'),invduedate=str_to_date('$FORM{invprintdate}','%d-%b-%y'),invyearend='$COOKIE->{YEAREND}' where id=$FORM{id} and acct_id='$COOKIE->{ACCT}'");
			}
		}
		else {				#  New invoice so get the next invoice no

			if ($FORM{invcusterms} =~ /^\d+$/) {		#  Calculate the due date
				$Sts = $dbh->do("insert into invoices (acct_id,cus_id,invinvoiceno,invcusref,invtype,invcusname,invcusaddr,invcuspostcode,invcusregion,invcoa,invcuscontact,invcusemail,invcusterms,invremarks,invcreated,invstatus,invstatuscode,invstatusdate,invfpflag,invitemcount,invitems,invdesc,invtotal,invvat,invprintdate,invduedate,invyearend) values ('$COOKIE->{ACCT}',$FORM{cus_id},'$FORM{invinvoiceno}','$FORM{invcusref}','$FORM{invtype}','$FORM{invcusname}','$FORM{invcusaddr}','$FORM{invcuspostcode}','$FORM{invcusregion}','$FORM{invcoa}','$FORM{invcuscontact}','$FORM{invcusemail}','$FORM{invcusterms}','$FORM{invremarks}',now(),'Printed','3',now(),'$FORM{invfpflag}',$FORM{invitemcount},'$FORM{invitems}','$FORM{invdesc}','$FORM{invtotal}','$FORM{invvat}',str_to_date('$FORM{invprintdate}','%d-%b-%y'),from_days(to_days(str_to_date('$FORM{invprintdate}','%d-%b-%y')) + '$FORM{invcusterms}'),'$COOKIE->{YEAREND}')");
			}
			else {		#  just ignore due date
				$Sts = $dbh->do("insert into invoices (acct_id,cus_id,invinvoiceno,invcusref,invtype,invcusname,invcusaddr,invcuspostcode,invcusregion,invcoa,invcuscontact,invcusemail,invcusterms,invremarks,invcreated,invstatus,invstatuscode,invstatusdate,invfpflag,invitemcount,invitems,invdesc,invtotal,invvat,invprintdate,invduedate,invyearend) values ('$COOKIE->{ACCT}',$FORM{cus_id},'$FORM{invinvoiceno}','$FORM{invcusref}','$FORM{invtype}','$FORM{invcusname}','$FORM{invcusaddr}','$FORM{invcuspostcode}','$FORM{invcusregion}','$FORM{invcoa}','$FORM{invcuscontact}','$FORM{invcusemail}','$FORM{invcusterms}','$FORM{invremarks}',now(),'Printed','3',now(),'$FORM{invfpflag}',$FORM{invitemcount},'$FORM{invitems}','$FORM{invdesc}','$FORM{invtotal}','$FORM{invvat}',str_to_date('$FORM{invprintdate}','%d-%b-%y'),str_to_date('$FORM{invprintdate}','%d-%b-%y'),'$COOKIE->{YEAREND}')");
			}
			$FORM{id} = $dbh->last_insert_id(undef, undef, qw(invoices undef));
		}

#  Separate and store the line item details

		$FORM{invitems} =~ s/^.*?<\/tbody>//gis;                            #  Get rid of the Column headers
		$FORM{invitems} =~ tr/\r\n//d;                                      #  remove any newlines
		$FORM{invitems} =~ s/<tbody.*?>//ig;                                #  Remove any additional tbody tags
		$FORM{invitems} =~ s/<\/tbody>//ig;
		$FORM{invitems} =~ s/<tr.*?>//gis;

		@Row = split(/\<\/tr\>/,$FORM{invitems});
		for $Row (@Row) {
		        $Row =~ s/<td.*?>//gis;
		        @Cell = split(/\<\/td\>/,$Row);
			if ($Cell[1]) {		#  ie make sure we don't pick up the last (</table>) line

#  remove any date/increment brackets

			        $Cell[0] =~ s/\[(\%|\+|\-) //g;
			        $Cell[0] =~ s/ (\%|\+|\-)\]//g;

#  Convert ampersands

			        $Cell[0] =~ s/\&amp;/\&/ig;

			        $Cell[0] =~ s/<br\/>/\n/ig;
				$Cell[0] =~ s/^\s+//;

			        if ($COOKIE->{VAT} =~ /N/i) {
					$Sts = $dbh->do("insert into items (acct_id,inv_id,itmtype,itmqty,itmdesc,itmtotal,itmdate,itmcat) values ('$COOKIE->{ACCT}',$FORM{id},'S','$Cell[2]','$Cell[0]','$Cell[3]',str_to_date('$FORM{invprintdate}','%d-%b-%y'),'$Cell[5]')");
			        }
		        	else {
					$Sts = $dbh->do("insert into items (acct_id,inv_id,itmtype,itmqty,itmdesc,itmtotal,itmvat,itmvatrate,itmdate,itmcat) values ('$COOKIE->{ACCT}',$FORM{id},'S','$Cell[2]','$Cell[0]','$Cell[3]','$Cell[5]','$Cell[4]',str_to_date('$FORM{invprintdate}','%d-%b-%y'),'$Cell[7]')");
			        }
			}
		}

#  Check to see whether we need to do the VAT

		&process_vat('S',$FORM{id});
		my $Tot = $FORM{invtotal} + $FORM{invvat};

#  Update the customer balance

		$Sts = $dbh->do("update customers set cusbalance=cusbalance + '$Tot' where id=$FORM{cus_id} and acct_id='$COOKIE->{ACCT}'");

#  Add to the debtors control account

		$Sts = $dbh->do("update coas set coabalance=coabalance + '$Tot' where acct_id='$COOKIE->{ACCT}' and coanominalcode='1100'");
		$Sts = $dbh->do("insert into nominals (acct_id,link_id,nomtype,nomcode,nomamount,nomdate) values ('$COOKIE->{ACCT}',$FORM{id},'S','1100','$Tot',str_to_date('$FORM{invprintdate}','%d-%b-%y'))");

#  Add to the relevant sales account

		unless ($FORM{txntype}) {
			$FORM{txntype} = $FORM{invcoa};
		}
		$Sts = $dbh->do("update coas set coabalance=coabalance + '$FORM{invtotal}' where acct_id='$COOKIE->{ACCT}' and coanominalcode='$FORM{txntype}'");
		$Sts = $dbh->do("insert into nominals (acct_id,link_id,nomtype,nomcode,nomamount,nomdate) values ('$COOKIE->{ACCT}',$FORM{id},'S','$FORM{txntype}','$FORM{invtotal}',str_to_date('$FORM{invprintdate}','%d-%b-%y'))");

		$Tot =~ tr/-//d;		#  remove any minus sign
		$Tot = sprintf("%1.2f",$Tot);

#  create audit trail record for the finalised invoice

		$Sts = $dbh->do("insert into audit_trails (acct_id,link_id,audtype,audaction,audtext,auduser) values ('$COOKIE->{ACCT}',$FORM{id},'update_invoice.pl','income','$Invoice_type $FORM{invinvoiceno} for &pound;$Tot raised to $FORM{invcusname}','$COOKIE->{USER}')");
	}
}

sub money_in {

#  Get the next transaction no

	&get_com_details();
	$FORM{txnno} = $Company[5];
	$Sts = $dbh->do("update companies set comnexttxn=comnexttxn+1 where reg_id=$Reg_id and id=$Com_id");

#  create a transaction record

	$Sts = $dbh->do("insert into transactions (acct_id,link_id,txncusname,txnmethod,txnamount,txndate,txntxntype,txnremarks,txnyearend,txntxnno) values ('$COOKIE->{ACCT}',$FORM{cus_id},'$FORM{invcusname}','$FORM{txnmethod}','$FORM{txnamount}',str_to_date('$FORM{invprintdate}','%d-%b-%y'),'income','$FORM{invdesc}','$COOKIE->{YEAREND}','$FORM{txnno}')");
	$New_txn_id = $dbh->last_insert_id(undef, undef, qw(transactions undef));

#  update nominal codes for bank/cash/cheque and customer unallocated balance

#  Bank, cash etc

	$Sts = $dbh->do("update coas set coabalance=coabalance + '$FORM{txnamount}' where acct_id='$COOKIE->{ACCT}' and coanominalcode='$FORM{txnmethod}'");
	$Sts = $dbh->do("insert into nominals (acct_id,link_id,nomtype,nomcode,nomamount,nomdate) values ('$COOKIE->{ACCT}',$New_txn_id,'T','$FORM{txnmethod}','$FORM{txnamount}',str_to_date('$FORM{invprintdate}','%d-%b-%y'))");

	if ($FORM{txnmethod} =~ /1310/) {		#  Cheque so increase cheque count
       		($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});
		$Sts = $dbh->do("update companies set comnocheques=comnocheques+1 where reg_id=$Reg_id and id=$Com_id");
	}

#  deduct this amount from debtors

	my $Tot = 0 - $FORM{txnamount};	#  reverse the sign

	$Sts = $dbh->do("update coas set coabalance = coabalance + '$Tot' where acct_id='$COOKIE->{ACCT}' and coanominalcode='1100'");
	$Sts = $dbh->do("insert into nominals (acct_id,link_id,nomtype,nomcode,nomamount,nomdate) values ('$COOKIE->{ACCT}',$New_txn_id,'T','1100','$Tot',str_to_date('$FORM{invprintdate}','%d-%b-%y'))");

#  Customer balance (this is initially allocated to the unallocated field and is then deducted when the invoices are processed)

	$Sts = $dbh->do("update customers set cuscredit=cuscredit + '$FORM{txnamount}' where acct_id='$COOKIE->{ACCT}' and id=$FORM{cus_id}");

#  Now get the total available to set against invoices
	warn "my \$Customers = \$dbh->prepare(\"select cuscredit from customers where acct_id='$COOKIE->{ACCT}' and id='$FORM{cus_id}'\")\n";
	my $Customers = $dbh->prepare("select cuscredit from customers where acct_id='$COOKIE->{ACCT}' and id='$FORM{cus_id}'");
	$Customers->execute;
	($FORM{txnamount}) = $Customers->fetchrow;
	$Customers->finish;

	$Tot =~ tr/-//d;
	$Tot = sprintf("%1.2f",$Tot);

	$Sts = $dbh->do("insert into audit_trails (acct_id,link_id,audtype,audaction,audtext,auduser) values ('$COOKIE->{ACCT}',$New_txn_id,'transactions','income','Received payment of &pound;$Tot from $FORM{invcusname}','$COOKIE->{USER}')");
}

sub pay_invoice {

#  then get the current balance of the invoice

	my $Invoices = $dbh->prepare("select invstatuscode,invtotal,invvat,invpaid,invpaidvat,invtype,invinvoiceno,invcusname,invcoa from invoices where acct_id='$COOKIE->{ACCT}' and id=$FORM{id}");
	$Invoices->execute;
	my @Invoice = $Invoices->fetchrow;
	$Invoices->finish;

	if ($Invoices->rows > 0 && $Invoice[0] > 2) {		#  OK this is a good invoice

		my $Owing = $Invoice[1] + $Invoice[2] - $Invoice[3] - $Invoice[4];
		$FORM{invtype} = $Invoice[5];
		$FORM{invinvoiceno} = $Invoice[6];
		$FORM{invcusname} = $Invoice[7];
		$FORM{invcoa} = $Invoice[8];
		$Invoice_type = "Invoice";
		if ($FORM{invtype} =~ /C/i) {
			$Invoice_type = "Credit Note";
		}

#  Convert to integer

		$P_txnamount = $FORM{txnamount};
		$P_Owing = $Owing;
		$P_txnamount =~ tr/\.//d;
		$P_Owing =~ tr/\.//d;

		if ($P_txnamount >= $P_Owing) {		#  sufficient funds to cover the

#  Deduct what is owed from what we have to play with

			$FORM{txnamount} -= $Owing;
			$FORM{invtotal} = $Invoice[1] - $Invoice[3];
			$FORM{invvat} = $Invoice[2] - $Invoice[4];

#  Update invoice paid fields

			$Sts = $dbh->do("update invoices set invpaid=invtotal,invpaidvat=invvat,invstatus='Paid',invstatuscode='2',invstatusdate=now(),invpaiddate=str_to_date('$FORM{invprintdate}','%d-%b-%y') where acct_id='$COOKIE->{ACCT}' and id=$FORM{id}");

		}
		else {

#  Calculate the percentage of net and vat that can be paid

			$FORM{invvat} = sprintf("%1.2f",($Invoice[2] - $Invoice[4]) * $FORM{txnamount} / $Owing);
			$FORM{invtotal} = $FORM{txnamount} - $FORM{invvat};
			$Owing = $FORM{txnamount};

#  Update invoice paid fields

			$Sts = $dbh->do("update invoices set invpaid=invpaid + '$FORM{invtotal}',invpaidvat=invpaidvat + '$FORM{invvat}',invstatus='Part-Paid',invstatuscode='7',invstatusdate=now() where acct_id='$COOKIE->{ACCT}' and id=$FORM{id}");

		}

#  Create an inv_txn record

		$Sts = $dbh->do("insert into inv_txns (acct_id,txn_id,inv_id,itnet,itvat,itdate,itmethod,itinvoiceno,ittxnno) values ('$COOKIE->{ACCT}',$New_txn_id,$FORM{id},'$FORM{invtotal}','$FORM{invvat}',str_to_date('$FORM{invprintdate}','%d-%b-%y'),'$FORM{txnmethod}','$Invoice[6]','$FORM{txnno}')");
		$New_inv_txn_id = $dbh->last_insert_id(undef, undef, qw(inv_txns undef));

		$Sts = $dbh->do("update customers set cusbalance=cusbalance - '$Owing',cuscredit=cuscredit - '$Owing' where acct_id='$COOKIE->{ACCT}' and id=$FORM{cus_id}");

#  deal with any VAT payments

		&process_vat('C',$New_inv_txn_id);

#  write an audit trail record

		$Owing =~ tr/-//d;
		$Owing = sprintf("%1.2f",$Owing);

		$Sts = $dbh->do("insert into audit_trails (acct_id,link_id,audtype,audaction,audtext,auduser) values ('$COOKIE->{ACCT}',$FORM{id},'update_invoice.pl','income','&pound;$Owing allocated to $Invoice_type $Invoice[6] to make it fully Paid','$COOKIE->{USER}')");
	}
}
1;
