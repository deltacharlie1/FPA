#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to list VAT entries by VAT Return

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
}

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");

$Accruals = $dbh->prepare("select * from vatreturns where acct_id='$COOKIE->{ACCT}' and str_to_date('$FORM{tbstart}','%d-%b-%y')<= perstartdate and str_to_date('$FORM{tbend}','%d-%b-%y')>=perenddate order by perstartdate");
$Accruals->execute;
$Accrual = $Accruals->fetchall_arrayref({});

#  List VAT entries in simple text format

$Report_date = `date +%d-%b-%y`;
chomp($Report_date);

print<<EOD;
Content-type: text/plain
Content-Disposition: attachment; filename=vatreturns.csv

EOD

print "\"VAT Quarter\",\"Box 1\",\"Box 2\",\"Box 3\",\"Box 4\",\"Box 5\",\"Box 6\",\"Box 7\",\"Box 8\",\"Box 9\"\n";
foreach $item (@$Accrual) {
	print "\"$item->{perquarter}\",\"$item->{perbox1}\",\"$item->{perbox2}\",\"$item->{perbox3}\",\"$item->{perbox4}\",\"$item->{perbox5}\",\"$item->{perbox6}\",\"$item->{perbox7}\",\"$item->{perbox8}\",\"$item->{perbox9}\"\n";
}
$Accruals->finish;
$dbh->disconnect;
exit;

