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

#$COOKIE->{DB} = "fpa";
#$COOKIE->{ACCT} = "1+1";
#$FORM{tbstart} = "01-Jul-10";
#$FORM{tbend} = "30-Jun-11";

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");
unless ($COOKIE->{NO_ADS}) {
	require "/usr/local/git/fpa/cgi/display_adverts.ph";
	&display_adverts();
}


#  List VAT entries in simple text format

$Report_date = `date +%d-%b-%y`;
chomp($Report_date);

#  Set up the header

print<<EOD;
Content-Type: text/plain\n\n

<div style="overflow:auto; width:670px;height:600px;padding-top:10px;background-color:#ffffff;color:#000000;font-weight:normal;">
<pre id="print_listing">
EOD

format STDOUT_TOP =
@<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<   Aged Creditors For: @>>>>>>>> to @<<<<<<<<
$COOKIE->{TAG},$FORM{tbstart},$FORM{tbend}

Report Date: @<<<<<<<<<<                                                                     Page No: @<<<
$Report_date,$%

Creditor Name            Up to 30 Days     31 - 60 Days     61 - 90 Days     91 to 120 Days   Over 120 Days
--------------------------------------------------------------------------------------------------------------
.

format SUMMARY =
--------------------------------------------------------------------------------------------------------------
@>>>>>>>>>>>>>>>>>>>>>  @>>>>>>>>>>>>>    @>>>>>>>>>>>>    @>>>>>>>>>>>>    @>>>>>>>>>>>>    @>>>>>>>>>>>>
$Curcus,sprintf('%1.2f',$Sl1),sprintf('%1.2f',$Sl2),sprintf('%1.2f',$Sl3),sprintf('%1.2f',$Sl4),sprintf('%1.2f',$Sl5)
--------------------------------------------------------------------------------------------------------------

.

format CUSTOMER =
@<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$Curcus
.
format STDOUT = 
         @>>>>>>>>>>>>  @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<    @>>>>>>>>>>>>
$Invoice->{printdate},$Invoice->{descr},$Amtoverdue
.

format FOOTER =
          Range Totals  @>>>>>>>>>>>>>    @>>>>>>>>>>>>    @>>>>>>>>>>>>    @>>>>>>>>>>>>    @>>>>>>>>>>>>
sprintf('%1.2f',$Tl1),sprintf('%1.2f',$Tl2),sprintf('%1.2f',$Tl3),sprintf('%1.2f',$Tl4),sprintf('%1.2f',$Tl5)
--------------------------------------------------------------------------------------------------------------
           Grand Total  @>>>>>>>>>>>>>
sprintf('%1.2f',$Tl1+$Tl2+$Tl3+$Tl4+$Tl5)
==============================================================================================================
.

$Curcus = "";

$Tl1 = "";
$Tl2 = "";
$Tl3 = "";
$Tl4 = "";
$Tl5 = "";

$Sl1 = "";
$Sl2 = "";
$Sl3 = "";
$Sl4 = "";
$Sl5 = "";

$Invoices = $dbh->prepare("select invoices.id as invid,invcusname,0-invtotal-invvat as amtdue,date_format(invprintdate,'%d-%b-%y') as printdate,concat('Invoice ',invinvoiceno,' (',invdesc,')') as descr,datediff(str_to_date('$FORM{tbend}','%d-%b-%y'),invprintdate) as overdue,sum(0-itnet-itvat) as amtpaid,0-invtotal-invvat+sum(itnet+itvat) as amtoverdue from invoices left join inv_txns on (invoices.id=inv_txns.inv_id and invoices.acct_id=inv_txns.acct_id) where invprintdate<=str_to_date('$FORM{tbend}','%d-%b-%y') and invstatuscode>'1' and invtype in ('P','C') and invoices.acct_id='$COOKIE->{ACCT}' group by invoices.id having amtpaid<amtdue or isnull(amtpaid)");
$Invoices->execute;

for ($i = 0; $i<1; $i++) {
while ($Invoice = $Invoices->fetchrow_hashref) {
	if ($Curcus !~ /$Invoice->{invcusname}/) {
		if ($Curcus) {

#  print customer summary and zeroise summary totals

			write SUMMARY;
		}

		$Tl1 += $Sl1;
		$Tl2 += $Sl2;
		$Tl3 += $Sl3;
		$Tl4 += $Sl4;
		$Tl5 += $Sl5;

		$Curcus = $Invoice->{invcusname};
		$Sl1 = "";
		$Sl2 = "";
		$Sl3 = "";
		$Sl4 = "";
		$Sl5 = "";

		write CUSTOMER;
	}

#  Now print the invoice

	$Amtoverdue = $Invoice->{amtoverdue} || $Invoice->{amtdue};

	if ($Invoice->{overdue} > 120) { $Sl5 += $Amtoverdue; }
	elsif ($Invoice->{overdue} > 90) { $Sl4 += $Amtoverdue; }
	elsif ($Invoice->{overdue} > 60) { $Sl3 += $Amtoverdue; }
	elsif ($Invoice->{overdue} > 30) { $Sl2 += $Amtoverdue; }
	elsif ($Invoice->{overdue} > 0) { $Sl1 += $Amtoverdue; }

	write;
}

$Tl1 += $Sl1;
$Tl2 += $Sl2;
$Tl3 += $Sl3;
$Tl4 += $Sl4;
$Tl5 += $Sl5;

write SUMMARY;
write FOOTER;
$Amtoverdue="";
write;

print "</pre></div>\n";
}
$Invoices->finish;
$dbh->disconnect;
exit;

