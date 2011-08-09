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

$SQL = "";
if ($FORM{invitem}) {
	$SQL .= "invoices.invdesc like '$FORM{invitem}%' and ";
}
if ($FORM{invtype}) {
	$SQL .= "invoices.invtype='$FORM{invtype}' and ";
}

use DBI;
my $dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");

#  Save the current filter settings

$Sts = $dbh->do("update tempstacks set f1='$FORM{tbselect}',f2='$FORM{tbstart}',f3='$FORM{tbend}' where acct_id='$COOKIE->{ACCT}' and caller='report'");

$Invoices = $dbh->prepare("select invinvoiceno,invcusname,invtype,invdesc,date_format(invprintdate,'%d-%b-%y') as printdate,invtotal,invvat,(invtotal+invvat) as invamount,invstatus from invoices where $SQL invprintdate>=str_to_date('$FORM{tbstart}','%d-%b-%y') and invprintdate<=str_to_date('$FORM{tbend}','%d-%b-%y') and invinvoiceno <> 'unlisted' and invoices.acct_id='$COOKIE->{ACCT}' order by invprintdate");
$Invoices->execute;
$Invoice = $Invoices->fetchall_arrayref({});

#  List VAT entries in simple text format

$Report_date = `date +%d-%b-%y`;
chomp($Report_date);

#  Set up the header

print<<EOD;
Content-Type: text/plain\n\n

<div id="print_listing" style="overflow:auto; width:670px;height:600px;padding-top:10px;background-color:#ffffff;color:#000000;font-weight:normal;">
<pre>
EOD

format STDOUT_TOP =
                                          Nominal Ledger Period:  @>>>>>>>> to @<<<<<<<<
$FORM{tbstart},$FORM{tbend}

Report Date: @<<<<<<<<<<                                                                                      Page No: @<<<
$Report_date,$%

Printed    Status     Invoice  Type  Customer                        Description                                         Net         VAT         Total
---------------------------------------------------------------------------------------------------------------------------------------------------------------
.

format STDOUT =
@<<<<<<<<  @<<<<<<<<  @<<<<<<  @<<<  @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<  @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<  @>>>>>>>>>  @>>>>>>>>>  @>>>>>>>>>>
$Invitem->{printdate},$Invitem->{invstatus},$Invitem->{invinvoiceno},$Invitem->{invtype},$Invitem->{invcusname},$Invitem->{invdesc},$Invitem->{invtotal},$Invitem->{invvat},$Invtotal
.

foreach $Invitem (@$Invoice) {
	$Invitem->{invtotal} =~ tr/-//d;
	$Invitem->{invvat} =~ tr/-//d;
	$Invitem->{invtotal} = sprintf('%1.2f',$Invitem->{invtotal});
	$Invitem->{invvat} = sprintf('%1.2f',$Invitem->{invvat});
	$Invtotal = sprintf('%1.2f',$Invitem->{invtotal}+$Invitem->{invvat});
	write;
}
print "</pre></div>\n";

$Invoices->finish;
$dbh->disconnect;
exit;

