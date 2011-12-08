#!/usr/bin/perl

$ACCESS_LEVEL = 5;

#  script to toggle between the live system and a testbed

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

#  Check to see if we are already in the test system (in which case switch back to the live one)
$ENV{HTTP_COOKIE} = $ENV{HTTP_COOKIE} || "";

@Cookie = split(/\;/,$ENV{HTTP_COOKIE});
foreach (@Cookie) {
	($Name,$Value) = split(/\=/,$_);
	$Name =~ s/^ //g;
	$Value =~ tr/\"//d;
	$Cookie{$Name} = $Value;
}

$New_com_id = $ENV{QUERY_STRING};
($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});

open(FILE,"</projects/tmp/$Cookie{'fpa-cookie'}");
while (<FILE>) {
	chomp($_);
	($Key,$Value) = split(/\t/,$_);
	$DATA{$Key} = $Value;
}
close(FILE);

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");

$Companies = $dbh->prepare("select comname,comcompleted,comvatscheme,comexpid,comyearend,frsrate,comvatqstart,comvatmsgdue,comyearendmsgdue,datediff(comvatmsgdue,now()),datediff(comyearend,now()),if(comfree>now(),'1',''),if(comno_ads>now(),'1',''),if(comrep_invs>now(),'1',''),if(comstmts>now(),'1',''),comuplds,if(compt_logo>now(),'1',''),if(comhmrc>now(),'1',''),comsuppt,comadd_user,comcis,combusiness from companies left join market_sectors on (combusiness=market_sectors.id) where companies.id=$New_com_id and reg_id=$Reg_id");
$Companies->execute;
@Company = $Companies->fetchrow;
$Companies->finish;

open(FILE,">/projects/tmp/$Cookie{'fpa-cookie'}");
print FILE "IP\t$DATA{IP}\nACCT\t$Reg_id+$New_com_id\nBACCT\t$DATA{BACCT}\nID\t$DATA{ID}\nPWD\t$DATA{PWD}\nPLAN\t$DATA{PLAN}\nVAT\t$Company[2]\nYEAREND\t$Company[4]\nUSER\t$DATA{USER}\nEXP\t$Company[3]\nFRS\t$Company[5]\nMIN\t$Company[6]\nMENU\t$DATA{MENU}\nTAG\t$Company[0]\nBTAG\t$DATA{BTAG}\nACCESS\t$DATA{ACCESS}\nNO_ADS\t$DATA{NO_ADS}\nREP_INVS\t$Company[13]\nSTMTS\t$Company[14]\nUPLDS\t$Company[15]\nPT_LOGO\t$Company[16]\nHMRC\t$Company[17]\nSUPPT\t$Company[18]\nCOOKIE\t$Cookie\nDB\tfpa\nADDU\t$Company[19]\nPREFS\t$DATA{PREFS}\nCIS\t$Company[20]\nBUS\t$Company[21]\n";

close(FILE);

$Companies->finish;
$dbh->disconnect;

print<<EOD;
Content-Type: text/html
Status: 301
Location: /cgi-bin/fpa/dashboard.pl

EOD

exit;
