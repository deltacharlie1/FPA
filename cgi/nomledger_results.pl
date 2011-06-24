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
my $dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");

$Coas = $dbh->prepare("select nominals.nomcode,nominals.nomtype,nominals.link_id,coadesc,coatype,nominals.nomamount as balance,date_format(nominals.nomdate,'%d-%b-%y') as printdate,concat(txncusname,' (',txnremarks,')') as txndescr,concat(invcusname,' (',invdesc,')') as invdescr from nominals left join coas on (nominals.nomcode=coas.coanominalcode and nominals.acct_id=coas.acct_id) left join transactions on (nominals.link_id=transactions.id and nominals.acct_id=transactions.acct_id) left join invoices on (nominals.link_id=invoices.id and nominals.acct_id=invoices.acct_id) where str_to_date('$FORM{tbstart}','%d-%b-%y')<=nominals.nomdate and str_to_date('$FORM{tbend}','%d-%b-%y')>=nominals.nomdate and nominals.acct_id='$COOKIE->{ACCT}' order by nominals.nomcode,nominals.nomdate");
$Coas->execute;

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
});

$Vars = {
	cookie => $COOKIE,
	tbstart => $FORM{tbstart},
	tbend => $FORM{tbend},
        entries => $Coas->fetchall_arrayref({})
};

print "Content-Type: text/html\n\n";
$tt->process('nomledger_results.tt',$Vars);

$Coas->finish;
$dbh->disconnect;
exit;

