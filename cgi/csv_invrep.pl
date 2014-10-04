#!/usr/bin/perl

$ACCESS_LEVEL = 3;

#  script to list invoices as a csv file for download

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

$Buffer = $ENV{QUERY_STRING};

@pairs = split(/&/,$Buffer);

foreach $pair (@pairs) {

        ($Name, $Value) = split(/=/, $pair);

        $Value =~ tr/+/ /;
        $Value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C",hex($1))/eg;
        $Value =~ tr/\\\'//d;
        $FORM{$Name} = $Value;
# warn "$Name = $Value\n";
}
#  exit;

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");

#  Construct the SQL filter

$SQL = "";

if ($FORM{startdate}) {
	$SQL .= "invprintdate >= str_to_date('$FORM{startdate}','%d-%b-%y') and ";
}
if ($FORM{enddate}) {
	$SQL .= "invprintdate <= str_to_date('$FORM{enddate}','%d-%b-%y') and ";
}
if ($FORM{invcusname}) {
	$SQL .= "invcusname like '$FORM{invcusname}%' and ";
}
if ($FORM{invinvoiceno}) {
	$SQL .= "invinvoiceno like '$FORM{invinvoiceno}%' and ";
}
if ($FORM{invcusref}) {
	$SQL .= "invcusref like '$FORM{invcusref}%' and ";
}
if ($FORM{invtype}) {
	$SQL .= "invtype='$FORM{invtype}' and ";
}
if ($FORM{invitem}) {
	$Invitems_selected = "1";
	$SQL .= "itmdesc like '%$FORM{invitem}%' and ";
}
if ($FORM{item_cat}) {
	$Invitems_selected = "1";
	$SQL .= "itmcat like '%$FORM{item_cat}%' and ";
}
if ($FORM{invstatuscode}) {
	$FORM{invstatuscode} =~ tr/V/0/;
	if ($FORM{invstatuscode} == 1) {
		$SQL = "invstatuscode=1 and ";		# because invoices don't get a data until they are finalised
	}
	elsif ($FORM{invstatuscode} > 6) {
		$SQL .= "invstatuscode>6 and ";
	}
	else {
		$SQL .= "invstatuscode='$FORM{invstatuscode}' and ";
	}
}
$SQL .= "invoices.acct_id='$COOKIE->{ACCT}'";
	
$Invoices = $dbh->prepare("select cus_id,invoices.id as invid,invinvoiceno,invcusname,invcoa,invtype,invdesc as description,date_format(invprintdate,'%d-%b-%y') as printdate,(invtotal+invvat) as invamount,invtotal,invvat,invstatus,(invpaid+invpaidvat) as invpaid from invoices where $SQL and invinvoiceno<>'unlisted' order by invprintdate");

$Invoices->execute;
print<<EOD;
Content-type: text/plain
Content-Disposition: attachment; filename=fpainvoices.csv

EOD

if ($COOKIE->{VAT} =~ /N/) {
	print "\"Date\",\"Invoice\",\"Type\",\"Nom Code\",\"Customer\",\"Description\",\"Total\",\"Status\",\"Paid\"\n";

	while ($Invoice = $Invoices->fetchrow_hashref) {
		print<<EOD;
"$Invoice->{printdate}","$Invoice->{invinvoiceno}","$Invoice->{invtype}","$Invoice->{invcoa}","$Invoice->{invcusname}","$Invoice->{description}",$Invoice->{invamount},"$Invoice->{invstatus}",$Invoice->{invpaid}
EOD
	}
}
else {
	print "\"Date\",\"Invoice\",\"Type\",\"Nom Code\",\"Customer\",\"Description\",\"Net\",\"VAT\",\"Gross\",\"Status\",\"Paid\"\n";

	while ($Invoice = $Invoices->fetchrow_hashref) {
		print<<EOD;
"$Invoice->{printdate}","$Invoice->{invinvoiceno}","$Invoice->{invtype}","$Invoice->{invcoa}","$Invoice->{invcusname}","$Invoice->{description}",$Invoice->{invtotal},$Invoice->{invvat},$Invoice->{invamount},"$Invoice->{invstatus}",$Invoice->{invpaid}
EOD
	}
}
$Invoices->finish;
$dbh->disconnect;
exit;

