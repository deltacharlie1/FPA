#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to add an invoice template

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

use CGI;
use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");

$Data = new CGI;
%FORM = $Data->Vars;

while (( $Key,$Value) = each %FORM) {

#  Remove any bad characters

	$Value =~ s/\%2b/\+/ig;
	$Value =~ tr/\\//d;
	$Value =~ s/\'/\\\'/g;
        $FORM{$Key} = $Value;
}

$FORM{invitems} =~ s/\xa3/\xc2\xa3/g;

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

	if ($FORM{submit} =~ /Delete/i) {
		$Sts = $dbh->do("delete from invoice_templates where acct_id='$COOKIE->{ACCT}' and id=$FORM{id}");
		print "Content-Type: text/plain\n\n";
		print "OK-list_invoice_templates.pl";
	}
	else {

#  step through the items, for first item, set invdesc, fora all items accumultate net and vat totals

		$Items = $FORM{invitems};

		$FORM{invitems} =~ tr/\n\r//d;
		$FORM{invitems} =~ s/.*?(\<td.*\<\/tr\>).*/$1/sm;
		$FORM{invitems} =~ s/<td nowrap.*?<\/td>//gsm;
		$FORM{invitems} =~ s/<td.*?>//g;
		$FORM{invitems} =~ s/<tr.*?>//g;
		$FORM{invitems} =~ s/<\/td>/\t/g;
		$FORM{invitems} =~ s/<\/tr>/\n/g;

#  We now have 1 row per item with the following columns tab separated:-
#
#  Description, unit price, Qty, Net  VAT rate, VAT,  Total

		$Net_total = 0;
		$VAT_total = 0;

		(@Row) = split(/\n/,$FORM{invitems});
		($FORM{invdesc},$Remainder) = split(/\t/,$Row[0]);

		foreach (@Row) {
			(@Cell) = split(/\t/,$_);
			$Net_total += $Cell[3];
			$VAT_total += $Cell[5];
		}

#  Save the record

	        if ($FORM{id}) {                #  We are updating an existing invoice/credit note
        	        $Sts = $dbh->do("update invoice_templates set invcusref='$FORM{invcusref}',invtype='$FORM{invtype}',invcusname='$FORM{invcusname}',invcusaddr='$FORM{invcusaddr}',invcuspostcode='$FORM{invcuspostcode}',invcusregion='$FORM{invcusregion}',invcoa='$FORM{invcoa}',invcuscontact='$FORM{invcuscontact}',invcusemail='$FORM{invcusemail}',invcusterms='$FORM{invcusterms}',invremarks='$FORM{invremarks}',invfpflag='$FORM{invfpflag}',invitemcount=$FORM{invitemcount},invitems='$Items',invdesc='$FORM{invdesc}',invtotal='$FORM{invtotal}',invvat='$FORM{invvat}',invlayout='$FORM{invlayout}',invprintdate=str_to_date('$FORM{invprintdate}','%d-%b-%y'),invrepeatfreq='$FORM{invrepeatfreq}',invnextinv='$FORM{invnextinv}',invlastinv='$FORM{invlastinv}',invemailsubj='$FORM{invemailsubj}',invemailmsg='$FORM{invemailmsg}' where id=$FORM{id} and acct_id='$COOKIE->{ACCT}'");
	        }

		if ($FORM{submit} =~ /Preview/i) {
			print "Content-Type: text/plain\n\n";
			print "OK-preview_invoice.pl?$FORM{id}?_template";
		}
		else {
			print "Content-Type: text/plain\n\n";
			print "OK-list_invoice_templates.pl";
		}
	}
}
$dbh->disconnect;
exit;
