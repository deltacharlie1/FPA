#!/usr/bin/perl

$Invdesc = sprintf<<EOD;
<TABLE class=items id=items cellSpacing=0 cellPadding=0 width=610 border=0>
<TBODY>
<TR>
<TH width=280>Description</TH>
<TH style="TEXT-ALIGN: right" width=50>Unit<BR>Price</TH>
<TH style="TEXT-ALIGN: right" width=30>Qty</TH>
<TH style="TEXT-ALIGN: right" width=50>Sub<BR>Total</TH>
<TH style="TEXT-ALIGN: center" width=30>VAT<BR>Rate</TH>
<TH style="TEXT-ALIGN: right" width=40>VAT<BR>Amt</TH>
<TH style="TEXT-ALIGN: right" width=60>Total</TH>
<TH style="TEXT-ALIGN: center" width=70>Edit</TH></TR></TBODY>
<TR>
<TD>Hosting Feb and Mar</TD>
<TD class=txtright>200.00</TD>
<TD class=txtright>1</TD>
<TD class=txtright>200.00</TD>
<TD class=txtcenter>17.5%</TD>
<TD class=txtright>35.00</TD>
<TD class=txtright>235.00</TD>
<TD nowrap="nowrap"><INPUT id=a1 type=button value=Amd> <INPUT id=d1 type=button value=Del></TD></TR></TABLE>
EOD
$Invdesc =~ s/^.*?\<td.*?>(.*?)\<\/td>.*$/$1/is;
print "$Invdesc\n";
exit

