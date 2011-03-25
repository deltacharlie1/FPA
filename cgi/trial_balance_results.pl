#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to list trial balance for a data range

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

$Coas = $dbh->prepare("select nomcode,coadesc,coatype,sum(nomamount) as balance from nominals left join coas on (nominals.nomcode=coas.coanominalcode and nominals.acct_id=coas.acct_id) where str_to_date('$FORM{tbstart}','%d-%b-%y')<=nomdate and str_to_date('$FORM{tbend}','%d-%b-%y')>=nomdate and nominals.acct_id='$COOKIE->{ACCT}' group by nomcode order by nomcode");
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
$tt->process('trial_balance_results.tt',$Vars);

$Coas->finish;
$dbh->disconnect;
exit;

