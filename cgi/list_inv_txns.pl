#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to display either a list of invoices linked to a particular transaction or, if only one invoice, the invoice

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");
unless ($COOKIE->{NO_ADS}) {
	require "/usr/local/git/fpa/cgi/display_adverts.ph";
	&display_adverts();
}


$Invoices = $dbh->prepare("select distinct invoices.id as invid,invinvoiceno,invcusname,invtype,invdesc,date_format(invprintdate,'%d-%b-%y') as printdate,date_format(invduedate,'%d-%b-%y') as invduedate,(invtotal+invvat) as invamount,invstatus,(invpaid+invpaidvat) as invpaid,to_days(invprintdate) as printdays,to_days(invduedate) as duedays from invoices left join inv_txns on (invoices.id=inv_id) where invinvoiceno <> 'unlisted' and invoices.acct_id=? and inv_txns.txn_id=$ENV{QUERY_STRING} order by invstatuscode desc,invinvoiceno desc");
$Invoices->execute("$COOKIE->{ACCT}");

if ($Invoices->rows == 1) {
	@Invoice = $Invoices->fetchrow;

	if ($Invoice[3] =~ /PR/i) {
		$Prog = "purchase";
	}
	else {
		$Prog = "invoice";
	}

	print<<EOD;
Content-Type: text/html
Status: 302
Location: /cgi-bin/fpa/update_$Prog.pl?$Invoice[0]

EOD
}
else {
	use Template;
	$tt = Template->new({
        	INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
	        WRAPPER => 'header.tt',
	});

	$Vars = {
        	title => 'Accounts - Invoices',
		cookie => $COOKIE,
		invoices => $Invoices->fetchall_arrayref({})
	};

	print "Content-Type: text/html\n\n";
	$tt->process('list_inv_txns.tt',$Vars);
}

$Invoices->finish;
$dbh->disconnect;
exit;

