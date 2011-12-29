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

($New_com_id,$New_reg_id) = split(/\?/,$ENV{QUERY_STRING});
($Reg_id,$Com_id) = split(/\+/,$COOKIE->{BACCT});

if ($COOKIE->{BACCT} == '1+1') {
	$Reg_id = $New_reg_id;
}

open(FILE,"</projects/tmp/$Cookie{'fpa-cookie'}");
while (<FILE>) {
	chomp($_);
	($Key,$Value) = split(/\t/,$_);
	$DATA{$Key} = $Value;
}
close(FILE);

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");

#  Get the basic company details for the new compnay

$Companies = $dbh->prepare("select companies.comname,comcompleted,comvatscheme,comexpid,comyearend,frsrate,comvatqstart,comvatmsgdue,comyearendmsgdue,datediff(comvatmsgdue,now()),datediff(comyearend,now()),if(comfree>now(),'1',''),if(comno_ads>now(),'1',''),if(comrep_invs>now(),'1',''),if(comstmts>now(),'1',''),comuplds,if(compt_logo>now(),'1',''),if(comhmrc>now(),'1',''),comsuppt,comadd_user,comcis,combusiness from companies left join reg_coms on (companies.id=reg_coms.com_id) left join market_sectors on (combusiness=market_sectors.id) where companies.id=$New_com_id and reg_id=$New_reg_id and (reg_coms.reg1_id=$Reg_id or reg_coms.reg2_id=$Reg_id)");

$Companies->execute;
@Company = $Companies->fetchrow;
$Companies->finish;

$Company[6] =~ s/(\d+)-(\d+)-(\d+)/$1,$2 - 1,$3/;

#  Get the COA select options

$Coas = $dbh->prepare("select coanominalcode,coadesc,coagroup from coas where acct_id='$New_reg_id+$New_com_id' and coagroup=? order by coanominalcode");
foreach $Coa ('4300','5000','6000','7000') {
        $Coas->execute($Coa);
        while (@Coa = $Coas->fetchrow) {
                if ($Coa[1] =~ /^Other Exp/i && ! $Opt{$Coa}) {
                        $Opt{$Coa} .= "<option value='$Coa[0]' selected='selected'>$Coa[1]</option>";
                }
                else {
                        $Opt{$Coa} .= "<option value='$Coa[0]'>$Coa[1]</option>";
                }
        }
}
$Coas->finish;

#  Update VAT related fields

if ($Company[2] !~ /N/i) {

        if ($Company[9] < 1) {                  #  VAT Reminder due

                $Dates = $dbh->prepare("select date_add('$Company[7]', interval 3 month),date_format(date_sub('$Company[7]',interval 1 day),'%m-%y'),date_format(last_day('$Company[7]'),'%d-%b-%y')");
                $Dates->execute;
                ($Company[7],$Prev_qend,$VATduedate) = $Dates->fetchrow;
                $Dates->finish;

#  Update comvatmsgdue & comvatreminder

                $Sts = $dbh->do("update companies set comvatmsgdue='$Company[7]',comvatreminder='1' where reg_id=$New_reg_id and id=$New_com_id");

#  Write reminder message

                $Sts = $dbh->do("insert into reminders (acct_id,remtext,remcode,remgrade,remstartdate,remenddate) values ('$New_reg_id+$New_com_id','VAT return due by $VATduedate','VATR','H',now(),'2099-01-01')");

        }
}

$ACCESS = $COOKIE->{PLAN} || $Company[12];

#  Update year end related fields

if ($Company[10] < 0) {

        $Sts = $dbh->do("update companies set comyearendmsgdue=date_add(comyearend,interval 8 month),comyearend=date_add(comyearend,interval 1 year) where reg_id=$New_reg_id and id=$New_com_id");

#  Add a couple of reminders

                $Dates = $dbh->prepare("select date_format(date_add('$Company[4]', interval 1 month),'%d-%b-%y'),date_format(date_add('$Company[4]',interval 10 month),'%d-%b-%y')");
                $Dates->execute;
                @Annual_date = $Dates->fetchrow;
                $Dates->finish;

                $Sts = $dbh->do("insert into reminders (acct_id,remtext,remcode,remgrade,remstartdate,remenddate) values ('$New_reg_id+$New_com_id','Year End Procedures need to be completed.  Please <a href=\"/cgi-bin/fpa/yearend_cleardown.pl\">click here</a> to do this.','YRN','H',now(),'2099-01-01')");
                $Sts = $dbh->do("insert into reminders (acct_id,remtext,remcode,remgrade,remstartdate,remenddate) values ('$New_reg_id+$New_com_id','Annual return (probably) due by $Annual_date[0]','GEN','N',now(),'2099-01-01')");
                $Sts = $dbh->do("insert into reminders (acct_id,remtext,remcode,remgrade,remstartdate,remenddate) values ('$New_reg_id+$New_com_id','Accounts due by $Annual_date[1]','GEN','N',now(),'2099-01-01')");

}

#  Set the correct FRS percentage

$Company[5] = sprintf("%1.3f",$Company[5]/100);

open(FILE,">/projects/tmp/$Cookie{'fpa-cookie'}");
print FILE "IP\t$DATA{IP}\nACCT\t$New_reg_id+$New_com_id\nBACCT\t$DATA{BACCT}\nID\t$DATA{ID}\nPWD\t$DATA{PWD}\nPLAN\t$DATA{PLAN}\nVAT\t$Company[2]\nYEAREND\t$Company[4]\nUSER\t$DATA{USER}\nEXP\t$Company[3]\nFRS\t$Company[5]\nMIN\t$Company[6]\nMENU\t$DATA{MENU}\nTAG\t$Company[0]\nBTAG\t$DATA{BTAG}\nACCESS\t$DATA{ACCESS}\nNO_ADS\t$DATA{NO_ADS}\nREP_INVS\t$Company[13]\nSTMTS\t$Company[14]\nUPLDS\t$Company[15]\nPT_LOGO\t$Company[16]\nHMRC\t$Company[17]\nSUPPT\t$Company[18]\nCOOKIE\t$DATA{COOKIE}\nDB\tfpa\nADDU\t$Company[19]\nPREFS\t$DATA{PREFS}\nCIS\t$Company[20]\nBUS\t$DATA{BUS}\n4300\t$Opt{'4300'}\n5000\t$Opt{'5000'}\n6000\t$Opt{'6000'}\n7000\t$Opt{'7000'}\n";

close(FILE);

$Companies->finish;
$dbh->disconnect;

print<<EOD;
Content-Type: text/html
Status: 301
Location: /cgi-bin/fpa/dashboard.pl

EOD

exit;
