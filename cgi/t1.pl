#!/usr/bin/perl

$Invoice[9] = sprintf<<EOD;
 <table id="itemstable" class="items" width="610" border="0" cellpadding="0" cellspacing="0">
 <tbody><tr>
 <th width="350">Description</th>
 <th style="text-align: right;" width="50">Unit<br>Price</th>
 <th style="text-align: right;" width="30">Qty</th>
 <th style="text-align: right;" width="50">Sub<br>Total</th>
 <th style="text-align: center;" width="30">VAT<br>Rate</th>
 <th style="text-align: right;" width="40">VAT<br>Amt</th>
 <th style="text-align: right;" width="60">Total</th>
 <th style="display: none;"></th>
 
 </tr>
<tr>
<td>Monthly Consultancy</td>
<td style="text-align: right;">100.00</td>
<td style="text-align: right;">1</td>
<td style="text-align: right;">100.00</td>
<td style="text-align: right;">20%</td>
<td style="text-align: right;">20.00</td>
<td style="text-align: right;">120.00</td>
<td style="display: none;"></td>

</tr>
<tr>
<td>Hosting of EU and US tracking systems<br/><br/>Sept 2011</td>
<td style="text-align: right;">650.00</td>
<td style="text-align: right;">1</td>
<td style="text-align: right;">650.00</td>
<td style="text-align: right;">20%</td>
<td style="text-align: right;">130.00</td>
<td style="text-align: right;">780.00</td>
<td style="display: none;">tracking</td>

</tr>
</tbody></table>
EOD

$Invoice[9] =~ s/^.*?<tr>//is;           #  Remove everything up to the first table row
$Invoice[9] =~ s/^.*?<tr>//is;           #  Then again to remove all headers

print $Invoice[9]."\n";
exit;

