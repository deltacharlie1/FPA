#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to add a new invoice 

#  Invoice status codes are as follows:-
#
#  0  -  Cancelled/Voided
#  1  -  Draft / Quote
#  2  -  Paid
#  3  -  Printed
#  6  -  Due (within 3/10ths of being overdue)
#  7  -  Part-Paid
#  9  -  Overdue


use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

use CGI;
use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");
unless ($COOKIE->{NO_ADS}) {
	require "/usr/local/git/fpa/cgi/display_adverts.ph";
	&display_adverts();
}


$Data = new CGI;
%FORM = $Data->Vars;

while (( $Key,$Value) = each %FORM) {

#  Remove any bad characters

	$Value =~ s/\%2b/\+/ig;
	$Value =~ tr/\\//d;
	$Value =~ s/\'/\\\'/g;
        $FORM{$Key} = $Value;
}

#  Do some basic validation

$Errs = "";

unless ($FORM{invcusname}) { $Errs .= "<li>You must enter a Customer Name</li>\n"; }
unless ($FORM{invitemcount} > 0) { $Errs .= "<li>You have not entered any line items, empty invoice!</li>\n"; }

if ($Errs) {
	print<<EOD;
Content-Type: text/plain

Errors!

$Errs
EOD
}
else {

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
Content-Type: text/html
Status: 301
Location: /cgi-bin/fpa/list_invoices.pl

EOD
	        }
		elsif ($FORM{submit} =~ /Draft/i) {
			&save_invoice('draft');

			print<<EOD;
Content-Type: text/plain

OK-update_invoice.pl?$FORM{id}

EOD
		}
		elsif ($FORM{submit} =~ /Quote/i) {
			&save_invoice('quote');
			print<<EOD;
Content-Type: text/plain

OK-print_invoice.pl?$FORM{id}?Q

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

			if ($FORM{invtype} =~ /C/i && $FORM{invremarks} =~ /^Refund/i) {

#  Get the Original invoice no

				$Original_inv = $FORM{invremarks};
				$Original_inv =~ s/.+\s(\d+)$/$1/;		#  Save the refund inv no for later use
			}
			&save_invoice('final');

			if ($Original_inv) {

#  get the original invoice totals

				$Original_invoices = $dbh->prepare("select id,invtotal-invpaid,invvat-invpaidvat from invoices where invinvoiceno='$Original_inv' and acct_id='$COOKIE->{ACCT}'");
				$Original_invoices->execute;
				@Original_invoice = $Original_invoices->fetchrow;
				$Original_invoices->finish;
				$Original_total = $Original_invoice[1]+$Original_invoice[2];

				if ($Original_invoice[1]+$Original_invoice[2] < 0-$FORM{invtotal}-$FORM{invvat}) {

#  update the original invoice to fully paid

					$Sts = $dbh->do("update invoices set invstatus='Paid',invstatuscode='2',invpaid=invtotal,invpaidvat=invvat,invremarks=concat(invremarks,'<br/><br/>Refund of &pound;$Original_total via Credit Note $FORM{invinvoiceno}') where id=$Original_invoice[0] and acct_id='$COOKIE->{ACCT}'");

#  update the credit note to a part paid status

					$Sts = $dbh->do("update invoices set invstatus='Part Paid',invstatuscode='7',invpaid=0-'$Original_invoice[1]',invpaidvat=0-'$Original_invoice[2]' where id=$FORM{id} and acct_id='$COOKIE->{ACCT}'");
				}
				elsif ($Original_invoice[1]+$Original_invoice[2] == 0-$FORM{invtotal}-$FORM{invvat}) {

#  update the original invoice to fully paid

					$Sts = $dbh->do("update invoices set invstatus='Paid',invstatuscode='2',invpaid=invtotal,invpaidvat=invvat,invremarks=concat(invremarks,'<br/><br/>Refund of &pound;$Original_total via Credit Note $FORM{invinvoiceno}') where id=$Original_invoice[0] and acct_id='$COOKIE->{ACCT}'");

#  update the credit note to fully paid

					$Sts = $dbh->do("update invoices set invstatus='Paid',invstatuscode='2',invpaid=0-'$Original_invoice[1]',invpaidvat=0-'$Original_invoice[2]' where id=$FORM{id} and acct_id='$COOKIE->{ACCT}'");
				}
				else {

#  update the original invoice to part paid

					$Sts = $dbh->do("update invoices set invstatus='Part Paid',invstatuscode='7',invpaid=invtotal,invpaidvat=invvat,invremarks=concat(invremarks,'<br/><br/>Refund of &pound;$Original_total via Credit Note $FORM{invinvoiceno}') where id=$Original_invoice[0] and acct_id='$COOKIE->{ACCT}'");

#  update the crdit note to fully paid

					$Sts = $dbh->do("update invoices set invstatus='Paid',invstatuscode='2',invpaid=0-'$Original_invoice[1]',invpaidvat=0-'$Original_invoice[2]' where id=$FORM{id} and acct_id='$COOKIE->{ACCT}'");

				}

#  Add an audit trail entry

				$Sts = $dbh->do("insert into audit_trails (acct_id,link_id,audtype,audaction,audtext,auduser) values ('$COOKIE->{ACCT}',$FORM{id},'update_invoice.pl','income','Invoice $Original_inv refunded &pound;$Original_total via Credit Note $FORM{invinvoiceno}','$COOKIE->{USER}')");

				$FORM{invfpflag} = "";
			}

			if ($FORM{invfpflag} =~ /Y/i) {		#  Paid in Full?
				$FORM{txnamount} = $FORM{invtotal} + $FORM{invvat};
				&money_in();
				&pay_invoice();
			}
			if ($FORM{invpdf} =~ /Y/i) {		#  Is PDF print required?	
	        	        print<<EOD;
Content-Type: text/plain

OK-print_invoice.pl?$FORM{id}?F

EOD
			}
			else {
	        	        print<<EOD;
Content-Type: text/plain

OK-update_invoice.pl?$FORM{id}?F

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
}
$dbh->disconnect;
exit;
