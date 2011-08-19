#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to assign unlisted invoices to a Customer/Supplier

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
$None_Checked = "1";

while (( $Key,$Value) = each %FORM) {

#  Remove any bad characters

	$Value =~ s/\%2b/\+/ig;
	$Value =~ tr/\\//d;
	$Value =~ s/\'/\\\'/g;
        $FORM{$Key} = $Value;
	if ($Key =~ /^c_/) {
		$None_Checked = "";
		push(@Invoices,$Value);
	}
}

#  Do some basic validation

$Errs = "";

unless ($FORM{cusname}) { $Errs .= "<li>You must enter an Assign-to Customer/Supplier</li>\n"; }
if ($None_Checked) { $Errs .= "<li>You have not selected any invoices to assign</li>\n"; }

if ($Errs) {
	print<<EOD;
Content-Type: text/plain

You have the following errors:-<ol>
$Errs
</ol>
Please correct them and resubmit
EOD
}
else {

#  For each invoice we get the outstanding amount and deduct (add) that from Unlisted cusbalance and 
#      add (deduct) that from Customer cusbalance
#  We then set the invoices cus_id to cusname (which, in fact, is the customer id)

	foreach $Id (@Invoices) {

		$Invoices = $dbh->prepare("select id,cus_id,invstatuscode,invtotal+invvat-invpaid-invpaidvat as outstanding from invoices where id=$Id and acct_id='$COOKIE->{ACCT}'");
		$Invoices->execute;
		$Invoice = $Invoices->fetchrow_hashref;

		if ($Invoice->{invstatuscode} > 2 && $Invoice->{outstanding} != 0) {

#  Adjust the cusbalance

			$Sts = $dbh->do("update customers set cusbalance=cusbalance-'$Invoice->{outstanding}' where acct_id='$COOKIE->{ACCT}' and id=$Invoice->{cus_id}");
			$Sts = $dbh->do("update customers set cusbalance=cusbalance+'$Invoice->{outstanding}' where acct_id='$COOKIE->{ACCT}' and id=$FORM{cusname}");
		}

#  Finally change the cus_id

		$Sts = $dbh->do("update invoices set cus_id=$FORM{cusname} where acct_id='$COOKIE->{ACCT}' and id=$Invoice->{id}");
	}
	$Invoices->finish;

        print<<EOD;
Content-Type: text/plain

OK
EOD
}
$dbh->disconnect;
exit;
