#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to list nominal ledger for a data range

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

$Buffer = $ENV{QUERY_STRING};

@pairs = split(/&/,$Buffer);

# print "Content-Type: text/plain\n\n";

foreach $pair (@pairs) {

        ($Name, $Value) = split(/=/, $pair);

        $Value =~ tr/+/ /;
        $Value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C",hex($1))/eg;
        $Value =~ tr/\\\'//d;
        $FORM{$Name} = $Value;
# print "$Name = $Value\n";
}
# exit;

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");
unless ($COOKIE->{NO_ADS}) {
	require "/usr/local/git/fpa/cgi/display_adverts.ph";
	&display_adverts();
}


#  Save the current filter settings

$Sts = $dbh->do("update tempstacks set f1='$FORM{tbselect}',f2='$FORM{tbstart}',f3='$FORM{tbend}' where acct_id='$COOKIE->{ACCT}' and caller='report'");

$Accruals = $dbh->prepare("select if(vatreturns.id,vatreturns.id,'aaa') as col1,perquarter,perbox3,perbox4,acrvat,date_format(acrprintdate,'%d-%b-%y') as printdate, concat(invcusname,'(',invinvoiceno,' - ',invdesc,')') as acrdesc,acrtype,acrvat as acramt,inv_txns.inv_id as inv_id from vataccruals left join inv_txns on (acrtxn_id=inv_txns.id and vataccruals.acct_id=inv_txns.acct_id) left join invoices on (inv_txns.inv_id=invoices.id and inv_txns.acct_id=invoices.acct_id) left join vatreturns on (vr_id=vatreturns.id and vataccruals.acct_id=vatreturns.acct_id) where vataccruals.acct_id='$COOKIE->{ACCT}' and str_to_date('$FORM{tbstart}','%d-%b-%y')<=acrprintdate and str_to_date('$FORM{tbend}','%d-%b-%y')>=acrprintdate order by col1,acrprintdate");
$Accruals->execute;
$Accrual = $Accruals->fetchall_arrayref({});

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
});

$Vars = {
	 ads => $Adverts,
	cookie => $COOKIE,
	tbstart => $FORM{tbstart},
	tbend => $FORM{tbend},
	curcode => $Accrual->[0]->{perquarter},
	numrows => $Accruals->rows,
        entries => $Accrual
};

print "Content-Type: text/html\n\n";
$tt->process('vatreport_results.tt',$Vars);

$Accruals->finish;
$dbh->disconnect;
exit;

