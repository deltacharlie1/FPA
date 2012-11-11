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

#  Save the current filter settings

$Sts = $dbh->do("update tempstacks set f1='$FORM{tbselect}',f2='$FORM{tbstart}',f3='$FORM{tbend}' where acct_id='$COOKIE->{ACCT}' and caller='report'");

if ($FORM{nomcoa}) {
	$Coas = $dbh->prepare("select nominals.nomcode,nominals.nomtype,nominals.link_id,coadesc,coatype,nominals.nomamount as balance,date_format(nominals.nomdate,'%d-%b-%y') as printdate,concat(txncusname,' (',txnremarks,')') as txndescr,concat(invcusname,' (',invdesc,')') as invdescr from nominals left join coas on (nominals.nomcode=coas.coanominalcode and nominals.acct_id=coas.acct_id) left join transactions on ((nominals.nomtype='T' or nominals.nomtype='J') and nominals.link_id=transactions.id and nominals.acct_id=transactions.acct_id) left join invoices on (nominals.nomtype='S' and nominals.link_id=invoices.id and nominals.acct_id=invoices.acct_id) where nominals.nomcode='$FORM{nomcoa}' and str_to_date('$FORM{tbstart}','%d-%b-%y')<=nominals.nomdate and str_to_date('$FORM{tbend}','%d-%b-%y')>=nominals.nomdate and nominals.acct_id='$COOKIE->{ACCT}' order by nominals.nomcode,nominals.nomdate");
}
else {
	$Coas = $dbh->prepare("select nominals.nomcode,nominals.nomtype,nominals.link_id,coadesc,coatype,nominals.nomamount as balance,date_format(nominals.nomdate,'%d-%b-%y') as printdate,concat(txncusname,' (',txnremarks,')') as txndescr,concat(invcusname,' (',invdesc,')') as invdescr from nominals left join coas on (nominals.nomcode=coas.coanominalcode and nominals.acct_id=coas.acct_id) left join transactions on ((nominals.nomtype='T' or nominals.nomtype='J') and nominals.link_id=transactions.id and nominals.acct_id=transactions.acct_id) left join invoices on (nominals.nomtype='S' and nominals.link_id=invoices.id and nominals.acct_id=invoices.acct_id) where str_to_date('$FORM{tbstart}','%d-%b-%y')<=nominals.nomdate and str_to_date('$FORM{tbend}','%d-%b-%y')>=nominals.nomdate and nominals.acct_id='$COOKIE->{ACCT}' order by nominals.nomcode,nominals.nomdate");
}
$Coas->execute;
$Coa = $Coas->fetchall_arrayref({});

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
});

$Vars = {
	 ads => $Adverts,
	cookie => $COOKIE,
	tbstart => $FORM{tbstart},
	tbend => $FORM{tbend},
	curcode => $Coa->[0]->{nomcode},
	curdesc => $Coa->[0]->{coadesc},
	numrows => $Coas->rows,
        entries => $Coa
};

print "Content-Type: text/html\n\n";
$tt->process('nomledger_results.tt',$Vars);

$Coas->finish;
$dbh->disconnect;
exit;

