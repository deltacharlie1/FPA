#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to list nominal ledger for a data range

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
}

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");
unless ($COOKIE->{NO_ADS}) {
	require "/usr/local/git/fpa/cgi/display_adverts.ph";
	&display_adverts();
}

#  Save the current filter settings

$Sts = $dbh->do("update tempstacks set f1='$FORM{tbselect}',f2='$FORM{tbstart}',f3='$FORM{tbend}' where acct_id='$COOKIE->{ACCT}' and caller='report'");

$Invoices = $dbh->prepare("select invoices.id as invid,invcusname,invtotal+invvat as amtdue,date_format(invprintdate,'%d-%b-%y') as printdate,concat('Invoice ',invinvoiceno,' (',invdesc,')') as descr,datediff(str_to_date('$FORM{tbend}','%d-%b-%y'),invprintdate) as overdue,sum(itnet+itvat) as amtpaid,invtotal+invvat-sum(itnet+itvat) as amtoverdue from invoices left join inv_txns on (invoices.id=inv_txns.inv_id and invoices.acct_id=inv_txns.acct_id) where invprintdate<=str_to_date('$FORM{tbend}','%d-%b-%y') and invstatuscode>'2' and invtype in ('S','R') and invoices.acct_id='$COOKIE->{ACCT}' group by invoices.id having amtpaid<amtdue or isnull(amtpaid)");
$Invoices->execute;
$Invoice = $Invoices->fetchall_arrayref({});

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
});

$Vars = {
	 ads => $Adverts,
	cookie => $COOKIE,
	tbstart => $FORM{tbstart},
	tbend => $FORM{tbend},
	suppress => $FORM{suppress},
	numrows => $Invoices->rows,
	curcus => "",
	colheader => "Debtor",
        entries => $Invoice
};

print "Content-Type: text/html\n\n";
$tt->process('aged_debtors_results.tt',$Vars);

$Invoices->finish;
$dbh->disconnect;
exit;

