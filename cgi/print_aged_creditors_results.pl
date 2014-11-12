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
$Invoice->[$i]->{printdate},$Invoice->[$i]->{descr},$Amtoverdue
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

$Invoices = $dbh->prepare("select id as invid,invcusname,invtotal+invvat as amtdue,date_format(invprintdate,'%d-%b-%y') as printdate,concat('Invoice ',invinvoiceno,' (',invdesc,')') as descr,datediff(str_to_date('$FORM{tbend}','%d-%b-%y'),invprintdate) as overdue,'0' as amtpaid,'0' as amtoverdue from invoices where acct_id='$COOKIE->{ACCT}' and invprintdate>=str_to_date('$FORM{tbstart}','%d-%b-%y') and invprintdate <=str_to_date('$FORM{tbend}','%d-%b-%y') and invstatuscode>'1' and invtype='P' order by invcusname,invinvoiceno");
$Invoices->execute;
$Invoice = $Invoices->fetchall_arrayref({});

foreach $i (0..@{$Invoice} - 1) {
        $Inv_txns = $dbh->prepare("select sum(itnet+itvat) as amtpaid from inv_txns where acct_id='$COOKIE->{ACCT}' and itdate<=str_to_date('$FORM{tbend}','%d-%b-%y') and $Invoice->[$i]->{invid}=inv_id");
        $Inv_txns->execute;
        $Inv_txn = $Inv_txns->fetchrow_hashref;
        $Amtowed = $Invoice->[$i]->{amtdue} - $Inv_txn->{amtpaid};

        $Invoice->[$i]->{amtpaid} = $Inv_txn->{amtpaid};
        $Invoice->[$i]->{amtoverdue} = $Amtowed;
}

$i = 0;
while ($i < @{$Invoice}) {
        if ($Invoice->[$i]->{amtoverdue} == 0) {
                splice(@{$Invoice},$i,1);
        }
        else {
                $i++;
        }
}

foreach $i (0..@{$Invoice}) {

	if ($Curcus !~ /$Invoice->[$i]->{invcusname}/) {
		if ($Curcus) {

#  print customer summary and zeroise summary totals

			write SUMMARY;
		}

		$Tl1 += $Sl1;
		$Tl2 += $Sl2;
		$Tl3 += $Sl3;
		$Tl4 += $Sl4;
		$Tl5 += $Sl5;

		$Curcus = $Invoice->[$i]->{invcusname};
		$Sl1 = "";
		$Sl2 = "";
		$Sl3 = "";
		$Sl4 = "";
		$Sl5 = "";

		write CUSTOMER;
	}

#  Now print the invoice

	$Amtoverdue = $Invoice->[$i]->{amtoverdue} || $Invoice->[$i]->{amtdue};

	if ($Invoice->[$i]->{overdue} > 120) { $Sl5 += $Amtoverdue; }
	elsif ($Invoice->[$i]->{overdue} > 90) { $Sl4 += $Amtoverdue; }
	elsif ($Invoice->[$i]->{overdue} > 60) { $Sl3 += $Amtoverdue; }
	elsif ($Invoice->[$i]->{overdue} > 30) { $Sl2 += $Amtoverdue; }
	elsif ($Invoice->[$i]->{overdue} > 0) { $Sl1 += $Amtoverdue; }

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

$Inv_txns->finish;
$Invoices->finish;
$dbh->disconnect;
exit;

