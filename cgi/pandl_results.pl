#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to display Profit and Loss Report

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

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");

$Incomes = $dbh->prepare("select coanominalcode,coadesc,coatype,sum(nomamount) as balance from coas left join nominals on (nominals.nomcode=coas.coanominalcode and nominals.acct_id=coas.acct_id) where coas.acct_id='$COOKIE->{ACCT}' and coatype='Income' and (isnull(nomdate) or (nomdate>=str_to_date('$FORM{tbstart}','%d-%b-%y') and nomdate<=str_to_date('$FORM{tbend}','%d-%b-%y'))) group by coanominalcode order by coanominalcode");
$Incomes->execute;
$Expenses = $dbh->prepare("select coanominalcode,coadesc,coatype,sum(nomamount) as balance from coas left join nominals on (nominals.nomcode=coas.coanominalcode and nominals.acct_id=coas.acct_id) where coas.acct_id='$COOKIE->{ACCT}' and coatype='Expenses' and (isnull(nomdate) or (nomdate>=str_to_date('$FORM{tbstart}','%d-%b-%y') and nomdate<=str_to_date('$FORM{tbend}','%d-%b-%y'))) group by coanominalcode order by coanominalcode");
$Expenses->execute;

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib']
});
$FORM{tbstart} =~ s/.*-//;
$FORM{tbend} =~ s/.*-//;

$Vars = {
	 ads => $Adverts,
        title => 'Accounts - P and L',
	cookie => $COOKIE,
	syr1 => sprintf("%02d",$FORM{tbstart}),
	eyr1 => sprintf("%02d",$FORM{tbend}),
	syr2 => sprintf("%02d",$FORM{tbstart} - 1),
	eyr2 => sprintf("%02d",$FORM{tbend} - 1),
	incomes => $Incomes->fetchall_arrayref({}),
	expenses => $Expenses->fetchall_arrayref({})
};

print "Content-Type: text/html\n\n";
$tt->process('pandl_results.tt',$Vars);

$Incomes->finish;
$Expenses->finish;
$dbh->disconnect;
exit;

