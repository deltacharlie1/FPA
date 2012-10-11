#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to list invoices

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


#  Construct the SQL filter

$SQL = "";

if ($FORM{tbstart}) {
	$SQL .= "txndate >= str_to_date('$FORM{tbstart}','%d-%b-%y') and ";
}
if ($FORM{tbend}) {
	$SQL .= "txndate <= str_to_date('$FORM{tbend}','%d-%b-%y') and ";
}
$SQL .= "transactions.acct_id='$COOKIE->{ACCT}'";

#  Save the current filter settings

$Sts = $dbh->do("update tempstacks set f1='$FORM{tbselect}',f2='$FORM{tbstart}',f3='$FORM{tbend}' where acct_id='$COOKIE->{ACCT}' and caller='report'");

$Txns = $dbh->prepare("select transactions.id,txntxnno,txnamount,date_format(txndate,'%d-%b-%y') as printdate,txnmethod,txncusname,txnremarks,inv_id,sum(itnet) as net,sum(itvat) as vat from transactions left join inv_txns on (transactions.id=inv_txns.txn_id and transactions.acct_id=inv_txns.acct_id) where $SQL group by transactions.id order by txndate ,txntxnno");
$Txns->execute;

$Txn = $Txns->fetchall_arrayref({});

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
});

$Vars = {
	 ads => $Adverts,
	cookie => $COOKIE,
	txns => $Txn,
	numrows => $Txns->rows
};

print "Content-Type: text/html\n\n";
$tt->process('nom_txns_results.tt',$Vars);

$Txns->finish;
$dbh->disconnect;
exit;

