#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to update an invoice template

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

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
# $Errs .= "$Key<br/>\n";
}

#  Do some basic validation

if ($FORM{submit} =~ /Delete/i) {
       	$Sts = $dbh->do("delete from invoice_templates where id=$FORM{id} and acct_id='$COOKIE->{ACCT}'");

         print<<EOD;
Content-Type: text/html
Status: 302
Location: /cgi-bin/fpa/list_templates.pl

EOD
}
else {		#  just save the updated record

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

#  Set up the Amd/Del buttons on the line items

	        if ($FORM{invitems}) {

        	        $FORM{invitems} =~ s/value=\"?Amd\"?/value=\"Amd\" onclick=\"amd(this);\"/igs;
                	$FORM{invitems} =~ s/value=\"?Del\"?/value=\"Del\" onclick=\"dlt(this);\"/igs;
	        }

#  Set up the invdesc

               	$FORM{invdesc} = $FORM{invitems};
	        $FORM{invdesc} =~ s/^.*?\<td.*?>(.*?)\<\/td>.*$/$1/is;          #  Extract the first column of the first row for description

		$Sts = $dbh->do("update invoice_templates set invcusref='$FORM{invcusref}',invcusname='$FORM{invcusname}',invcusaddr='$FORM{invcusaddr}',invcuspostcode='$FORM{invcuspostcode}',invcusregion='$FORM{invcusregion}',invcoa='$FORM{invcoa}',invcuscontact='$FORM{invcuscontact}',invcusemail='$FORM{invcusemail}',invcusterms='$FORM{invcusterms}',invremarks='$FORM{invremarks}',invitemcount='$FORM{invitemcount}',invitems='$FORM{invitems}',invdesc='$FORM{invdesc}',invtotal='$FORM{invtotal}',invvat='$FORM{invvat}',invrepeatfreq='$FORM{invrepeatfreq}',invnextinvdate=str_to_date('$FORM{invprintdate}','%d-%b-%y'),invemailmsg='$FORM{invemailmsg}' where id=$FORM{id} and acct_id='$COOKIE->{ACCT}'");

       	        print<<EOD;
Content-Type: text/plain

OK-list_templates.pl?$FORM{cus_id}

EOD
	}
}
$dbh->disconnect;
exit;
