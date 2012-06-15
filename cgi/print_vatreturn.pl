#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to update a VAT return

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

use CGI;
use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");
unless ($COOKIE->{NO_ADS}) {
	require "/usr/local/git/fpa/cgi/display_adverts.ph";
	&display_adverts();
}


$Data = new CGI;
%FORM = $Data->Vars;

while (( $Key,$Value) = each %FORM) {

#  Remove any bad characters

	$Value =~ tr/\\//d;
	$Value =~ s/\'/\\\'/g;
        $FORM{$Key} = $Value;
}

#  Get some dates

$Dates = $dbh->prepare(" select date_format(str_to_date('$FORM{qend}','%d-%b-%y'),'%m-%y'),concat(date_format(date_add(str_to_date('$FORM{qend}','%d-%b-%y'),interval -2 month),'%Y-%m'),'-01'),str_to_date('$FORM{qend}','%d-%b-%y'),last_day(date_add(str_to_date('$FORM{qend}','%d-%b-%y'),interval 1 day)),date_add(str_to_date('$FORM{qend}','%d-%b-%y'),interval 1 day)");
$Dates->execute;
@Date = $Dates->fetchrow;
$Dates->finish;

#  List VAT entries in simple text format

$Report_date = `date +%d-%b-%y`;
chomp($Report_date);

$Tot_input = 0;
$Tot_output = 0;

#  Set up the header

print<<EOD;
Content-Type: text/plain\n\n

<div style="overflow:auto; width:600px;height:600px;padding-top:10px;background-color:#ffffff;color:#000000;font-weight:normal;">
<pre id="print_listing">
EOD

format STDOUT_TOP =
                  VAT Period:  @>>>>>>>>>>  to  @<<<<<<<<<<
$FORM{qstart},$FORM{qend}

Report Date: @<<<<<<<<<<                                       Page No: @<<<
$Report_date,$%

VAT Date    Detail                                   VAT Output  VAT Input
---------------------------------------------------------------------------
.

format STDOUT = 
@<<<<<<<<<  @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<  @>>>>>>>>  @>>>>>>>>
$Accrual[0],$Accrual[1],$Output,$Input
.

if ($COOKIE->{VAT} =~ /S/i) {
       	$Accruals = $dbh->prepare("select date_format(acrprintdate,'%d-%b-%y') as vatdate, invcusname,invinvoiceno,acrtype,acrvat as acramt,invoices.id as inv_id from vataccruals,invoices where vataccruals.acrtxn_id=invoices.id and vataccruals.acct_id=invoices.acct_id and vr_id=$FORM{id} and vataccruals.acct_id='$COOKIE->{ACCT}' order by acrprintdate");
}
else {
#       	$Accruals = $dbh->prepare("select date_format(acrprintdate,'%d-%b-%y') as vatdate, invcusname,invinvoiceno,acrtype,acrvat as acramt,inv_txns.inv_id as inv_id from vataccruals,inv_txns,invoices where vataccruals.acrtxn_id=inv_txns.id and vataccruals.acct_id=inv_txns.acct_id and inv_txns.inv_id=invoices.id and inv_txns.acct_id=invoices.acct_id and vr_id=$FORM{id} and vataccruals.acct_id='$COOKIE->{ACCT}' order by acrprintdate");
       	$Accruals = $dbh->prepare("select date_format(vataccruals.acrprintdate,'%d-%b-%y') as vatdate, invcusname,invinvoiceno,vataccruals.acrtype,vataccruals.acrvat as acramt,inv_txns.inv_id as inv_id,joudesc,joujnlno,vataccruals.acrnominalcode from vataccruals left join inv_txns on (inv_txns.acct_id=vataccruals.acct_id and inv_txns.id=vataccruals.acrtxn_id and acrtype<>'J') left join invoices on (inv_txns.acct_id=invoices.acct_id and inv_txns.inv_id=invoices.id),vataccruals a left join journals on (a.acrtxn_id=journals.id and a.acct_id=journals.acct_id and acrtype='J') where vataccruals.id=a.id and vataccruals.vr_id=$FORM{id} and vataccruals.acct_id='$COOKIE->{ACCT}' order by vataccruals.acrprintdate");
}

$Accruals->execute;
while (@Accrual = $Accruals->fetchrow) {
	if ($Accrual[3] =~ /J/i) {
		$Accrual[1] = substr($Accrual[6],0,21)." (Journal - $Accrual[7])";
		if ($Accrual[4] > 0) {
			$Accrual[3] = 'P';		#  Force it to purchase type
		}
	}
	else {
		$Accrual[1] = substr($Accrual[1],0,21)." (Invoice - $Accrual[2])";
	}
	if ($Accrual[4] != 0) {
		if ($Accrual[8] > 4999) {		#  If expense then input and reverse sign
			$Accrual[4] =sprintf('%1.2f',0 - $Accrual[4]);
			$Input = $Accrual[4];
			$Output = "";
			$Tot_input += $Input;
		}
		else {
			$Output = $Accrual[4];
			$Input = "";
			$Tot_output += $Output;
		}
		write;
	}
}
print "---------------------------------------------------------------------------\n";
printf "            Totals                                    %9.2f  %9.2f\n",$Tot_output,$Tot_input;
print "===========================================================================\n</pre>\n</div>";

$Accruals->finish;
$dbh->disconnect;
exit;
