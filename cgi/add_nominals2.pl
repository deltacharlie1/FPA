#!/usr/bin/perl

$ACCESS_LEVEL = 5;

#  Save new nominal codes

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

use CGI;
use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");

#  Get the laast existing account code for 4300,5000,6000,7000 groups

$Coas = $dbh->prepare("select coanominalcode from coas where acct_id='$COOKIE->{ACCT}' and coagroup=? order by coanominalcode desc limit 1");

foreach $Coa ('4300','5000','6000','7000') {
	$Coas->execute($Coa);
	($Coa{$Coa}) = $Coas->fetchrow;
}
$Coas->finish;
$CoaMax{'4300'} = 4900;
$CoaMax{'5000'} = 5400;
$CoaMax{'6000'} = 6400;
$CoaMax{'7000'} = 7400;

$Data = new CGI;
%FORM = $Data->Vars;

while (( $Key,$Value) = each %FORM) {

#  Remove any bad characters

	$Value =~ s/\%2b/\+/ig;
	$Value =~ tr/\\//d;
	$Value =~ s/\'/\\\'/g;
        $DATA{$Key} = $Value;
}

($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});

$DATA{data} =~ s/<(?!\/).+?>//g;
$DATA{data} =~ s/<\/tr>/\n/ig;
$DATA{data} =~ s/<\/td>/\t/ig;

@Nomcodes = split(/\n/,$DATA{data});
foreach $Nomcode (@Nomcodes) {
        @bCell = split(/\t/,$Nomcode);

	if ($bCell[4] =~ /new/i) {
		if ($Coa{$bCell[5]} < $CoaMax{$bCell[5]}) {
			$Coa{$bCell[5]} = $Coa{$bCell[5]} + 10;
			$Sts = $dbh->do("insert into coas (acct_id,coanominalcode,coadesc,coatype,coagroup,coareport) values ('$COOKIE->{ACCT}','$Coa{$bCell[5]}','$bCell[1]','$bCell[3]','$bCell[5]','$bCell[6]')");
		}
	}
}
$dbh->disconnect;
print<<EOD;
Content-Type: text/plain
Status: 301
Location: /cgi-bin/fpa/add_nominals.pl

EOD
exit;
