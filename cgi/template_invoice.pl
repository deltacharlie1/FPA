#!/usr/bin/perl

#  script to add a new invoice 

#  1.  Run through all template invoices with a invnextinvdate <= today

#  For each one

#      2.  Convert any Date templates and/or increments
#      3.  Calculate and save the next invoice date (or delete if beyond last increment)
#      4.  Check the current VAT rate
#      5.  run process_invoice
#      6.  run print_invoice

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");

$Delete_flag = "";

$Tis = $dbh->prepare("select * from invoice_templates");
$Tis->execute;

while ($Ti = $Tis->fetchrow_hashref) {;
	
	while (($Key,$Value) = each %$Ti) {
		if ($Key =~ /invitems/i) {

			$Good_rows = 0;

			$Save_value = $Value;
			$Value =~ s/(\<tr.*?\/tr\>)/&process_row($1)/ges;
			$Save_value =~ s/(\<tr.*?\/tr\>)/&process_save_row($1)/ges;
			print "$Value\n";
		}
	}
	next;
}

print "Good_rows = $Good_rows\n";
exit;
	
#  Before we do anything else, set the invcoa depending on whether invcusregion = UK/EU/NEU.

	$FORM{invcusregion} = $FORM{invcusregion} || 'UK';

	if ($FORM{invcusregion} =~ /UK/i) {
		$FORM{invcoa} = "4000";
	}
	elsif ($FORM{invcusregion} =~ /NEU/i) {
		$FORM{invcoa} = "4200";
	}
	else {
		$FORM{invcoa} = "4100";
	}

#  Now see if this is a template or real invoice

	unless ($FORM{submit} =~ /Template/i) {		#  'Immediate' invoice, therefore not template

#  Is this a new Draft Invoice (or credit note?)

		require "/usr/local/httpd/cgi-bin/fpa/process_invoice.ph";

        	if ($FORM{submit} =~ /Delete/i) {
                	$Sts = $dbh->do("delete from invoices where id=$FORM{id} and acct_id='$COOKIE->{ACCT}'");

	                print<<EOD;
Content-Type: text/plain

OK-list_customer_invoices.pl?$FORM{cus_id}

EOD
	        }
		elsif ($FORM{submit} =~ /Draft/i) {
			&save_invoice('draft');

			print<<EOD;
Content-Type: text/plain

OK-update_invoice.pl?$FORM{id}

EOD
		}
	        elsif ($FORM{submit} =~ /Preview/i) {
			&save_invoice('draft');

        	        print<<EOD;
Content-Type: text/plain

OK-preview_invoice.pl?$FORM{id}

EOD
	        }
        	elsif ($FORM{submit} =~ /Final/i) {
			&save_invoice('final');

			if ($FORM{invfpflag} =~ /Y/i) {		#  Paid in Full?
				$FORM{txnamount} = $FORM{invtotal} + $FORM{invvat};
				&money_in();
				&pay_invoice();
			}
			if ($FORM{invpdf} =~ /Y/i) {		#  Is PDF print required?	
	        	        print<<EOD;
Content-Type: text/plain

OK-print_invoice.pl?$FORM{id}

EOD
			}
			else {
	        	        print<<EOD;
Content-Type: text/plain

OK-update_invoice.pl?$FORM{id}

EOD
			}
        	}
	}
	else {			#  repeat invoice (ie template) so just store in templates

#  Set up the Amd/Del buttons on the line items

	        if ($FORM{invitems}) {

        	        $FORM{invitems} =~ s/value=\"?Amd\"?/value=\"Amd\" onclick=\"amd(this);\"/igs;
                	$FORM{invitems} =~ s/value=\"?Del\"?/value=\"Del\" onclick=\"dlt(this);\"/igs;
	        }

#  Set up the invdesc

               	$FORM{invdesc} = $FORM{invitems};
	        $FORM{invdesc} =~ s/^.*?\<td.*?>(.*?)\<\/td>.*$/$1/is;          #  Extract the first column of the first row for description

#  Is this an existing customer?

	        if ($FORM{cus_id} > 0) {

#  Set the customer/supplier flag

        	        $Sts = $dbh->do("update customers set cussales='Y' where id=$FORM{cus_id} and acct_id='$COOKIE->{ACCT}'");
	        }
        	else {

#  First get the 'Unlisted' customer id (if it exists)

                	$Customers = $dbh->prepare("select id from customers where cusname='Unlisted' and acct_id='$COOKIE->{ACCT}'");
	                $Customers->execute;
        	        if ($Customers->rows > 0) {
#  Get the id
                	        ($FORM{cus_id}) = $Customers->fetchrow;
                        	$Sts = $dbh->do("update customers set cussales='Y' where id=$FORM{cus_id} and acct_id='$COOKIE->{ACCT}'");
	                }
        	        else {
#  Create new unlisted customer
                	        $Sts = $dbh->do("insert into customers (acct_id,cusname,cussales) values ('$COOKIE->{ACCT}','Unlisted','Y')");
#  ... and get the id
                        	$FORM{cus_id} = $dbh->last_insert_id(undef, undef, qw(customers undef));
	                }
			$Customers->finish;
		}
		$Sts = $dbh->do("insert into invoice_templates (acct_id,cus_id,invcusref,invtype,invcusname,invcusaddr,invcuspostcode,invcusregion,invcoa,invcuscontact,invcusemail,invcusterms,invremarks,invcreated,invitemcount,invitems,invdesc,invtotal,invvat,invrepeatfreq,invnextinvdate,invemailmsg) values ('$COOKIE->{ACCT}',$FORM{cus_id},'$FORM{invcusref}','$FORM{invtype}','$FORM{invcusname}','$FORM{invcusaddr}','$FORM{invcuspostcode}','$FORM{invcusregion}','$FORM{invcoa}','$FORM{invcuscontact}','$FORM{invcusemail}','$FORM{invcusterms}','$FORM{invremarks}',now(),$FORM{invitemcount},'$FORM{invitems}','$FORM{invdesc}','$FORM{invtotal}','$FORM{invvat}','$FORM{invrepeatfreq}',str_to_date('$FORM{invnextinvdate}','%d-%b-%y'),'$FORM{invemailmsg}')");

       	        print<<EOD;
Content-Type: text/plain

OK-list_templates.pl?$FORM{cus_id}

EOD
	}
$dbh->disconnect;
exit;

sub sub_dates {
	my $Date,$Mth,$Yr,$Template = $_[0];
	$Template =~ tr/a-zA-Z0-9//cd;

	($Date,$Mth,$Yr) = ($Template =~ /(\d+)(\w?)(\w)/);

#  Determine the date format

	my $DF = "";
	if ($Mth) {
		$DF .= "%".$Mth;
	}
	if ($Yr) {
		$DF .= " %".$Yr;
	}
	unless ($DF) {
		$DF = "%b %Y";
	}

	my $Dates = $dbh->prepare("select date_format(date_add(now(), interval $Date month),'$DF')");
	$Dates->execute;
	($Date) = $Dates->fetchrow;
	$Dates->finish;

	return $Date; 
}

sub sub_incrs {
	my $Incr,$Txt,$Of,$Template = $_[0];
	$Template =~ tr/a-zA-Z0-9 //cd;
	if ($Template =~ /^ *(\d+) *$/) {
		$Incr = $1;
		$Incr++;
		if ($_[1] =~ /V/i) {
			return "$Incr";
		}
		else {
			return "[+ $Incr +]";
		}
	}
	else {
		($Incr,$Txt,$Of) = ($Template =~ /^ *(\d+) +(\w+) +(\d+)/);
#		$Of = 23;
		$Incr++;
		if ($Incr > $Of) {
			$Flag = "";
			return "";
		}
		else {
			if ($_[1] =~ /V/i) {
				return "$Incr $Txt $Of";
			}
			else {
				return "[+ $Incr $Txt $Of +]";
			}
		}
	}

}

sub process_row {
	$Flag = "1";
	my $Row = $_[0];
	$Row =~ s/(\[\%.+?\%\])/&sub_dates($1)/ges;
	$Row =~ s/(\[\+.+?\+\])/&sub_incrs($1,"V")/ges;
	if ($Flag) {
		$Good_rows++;
		return $Row;
	}
	else {
		return "";
	}
}

sub process_save_row {
	my $Row = $_[0];
	$Row =~ s/(\[\%.+?\%\])/&sub_dates($1)/ges;
	$Row =~ s/(\[\+.+?\+\])/&sub_incrs($1,"T")/ges;
	return $Row;
}
