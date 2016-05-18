#!/usr/bin/perl

$ACCESS_LEVEL = 1;

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

$Companies = $dbh->prepare("select companies.comname,comcompleted,comvatscheme,comexpid,comyearend,frsrate,comvatqstart,comvatmsgdue,comyearendmsgdue,datediff(comvatmsgdue,now()) as diffvatmsgdue,datediff(comyearend,now()) as diffyearenddue,comuplds,if(compt_logo>now(),'1','') as pt_logo,comadd_user,comcis,combusiness,comsublevel,datediff(comsubdue,now()) as subdue from companies left join reg_coms on (companies.id=reg_coms.com_id) left join market_sectors on (combusiness=market_sectors.id) where companies.id=$New_com_id and reg_id=$New_reg_id and (reg_coms.reg1_id=$Reg_id or reg_coms.reg2_id=$Reg_id)");
$Companies->execute;
$Company = $Companies->fetchrow_hashref;
$Companies->finish;

$Company->{comvatstart} =~ s/(\d+)-(\d+)-(\d+)/$1,$2 - 1,$3/;

if ($Company->{comvatscheme} !~ /N/i) {

	if ($Company->{diffvatmsgdue} < 1) {			#  VAT Reminder due

		$Dates = $dbh->prepare("select date_add('$Company->{comvatmsgdue}', interval 3 month),date_format(date_sub('$Company->{comvatmsgdue}',interval 1 day),'%m-%y'),date_format(last_day('$Company->{comvatmsgdue}'),'%d-%b-%y')");
		$Dates->execute;
		($Company->{comvatmsgdue},$Prev_qend,$VATduedate) = $Dates->fetchrow;
		$Dates->finish;

#  Update comvatmesgdue and comvatreminder

		$Sts = $dbh->do("update companies set comvatmsgdue='$Company->{comvatmsgdue}',comvatreminder='1' where reg_id=$New_reg_id and id=$New_com_id");

#  Write reminder message

		$Sts = $dbh->do("insert into reminders (acct_id,remtext,remcode,remgrade,remstartdate,remenddate) values ('$New_reg_id+$New_com_id','VAT return due by $VATduedate','VATR','H',now(),'2099-01-01')");

	}
}

$ACCESS = $DATA{PLAN};

#############  Similar processing for Year End   ######################

if ($Company->{diffyearenddue} < 0) {

	$Sts = $dbh->do("update companies set comyearendmsgdue=date_add(comyearend,interval 8 month),comyearend=date_add(comyearend,interval 1 year) where reg_id=$New_reg_id and id=$New_com_id");

#  Add a couple of reminders

		$Dates = $dbh->prepare("select date_format(date_add('$Company->{comyearend}', interval 1 month),'%d-%b-%y'),date_format(date_add('$Company->{comyearend}',interval 10 month),'%d-%b-%y')");
		$Dates->execute;
		@Annual_date = $Dates->fetchrow;
		$Dates->finish;

		$Sts = $dbh->do("insert into reminders (acct_id,remtext,remcode,remgrade,remstartdate,remenddate) values ('$New_reg_id+$New_com_id','Year End Procedures need to be completed.  Please <a href=\"/cgi-bin/fpa/yearend_cleardown.pl\">click here</a> to do this.','YRN','H',now(),'2099-01-01')");
		$Sts = $dbh->do("insert into reminders (acct_id,remtext,remcode,remgrade,remstartdate,remenddate) values ('$New_reg_id+$New_com_id','Annual return (probably) due by $Annual_date[0]','GEN','N',now(),'2099-01-01')");
		$Sts = $dbh->do("insert into reminders (acct_id,remtext,remcode,remgrade,remstartdate,remenddate) values ('$New_reg_id+$New_com_id','Accounts due by $Annual_date[1]','GEN','N',now(),'2099-01-01')");

}

#  Get the User defined account codes

$Coas = $dbh->prepare("select coanominalcode,coadesc,coagroup from coas where acct_id='$New_reg_id+$New_com_id' and coagroup=? order by coanominalcode");
foreach $Coa ('1000','1500','3100','4300','5000','6000','7000') {
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

#  Set the correct FRS percentage

$Company->{frsrate} = sprintf("%1.3f",$Company->{frsrate}/100);

$IP_Addr = $ENV{'REMOTE_ADDR'};
open(COOKIE,">/projects/tmp/$Cookie{'fpa-cookie'}");
print COOKIE "IP\t$IP_Addr\nACCT\t$New_reg_id+$New_com_id\nBACCT\t$DATA{BACCT}\nID\t$DATA{ID}\nPWD\t$DATA{PWD}\nPLAN\t$DATA{PLAN}\nVAT\t$Company->{comvatscheme}\nYEAREND\t$Company->{comyearend}\nUSER\t$DATA{USER}\nEXP\t$Company->{comexpid}\nFRS\t$Company->{frsrate}\nMIN\t$Company->{comvatstart}\nMENU\t$DATA{MENU}\nTAG\t$Company->{comname}\nBTAG\t$DATA{BTAG}\nACCESS\t$DATA{ACCESS}\nUPLDS\t$DATA{UPLDS}\nPT_LOGO\t$Company->{pt_logo}\nCOOKIE\t$Cookie\nDB\t$DATA{DB}\nADDU\t$Company->{comadd_user}\nPREFS\t$COOKIE->{PREFS}\nCIS\t$Company->{comcis}\nBUS\t$DATA{BUS}\n4300\t$Opt{'4300'}\n5000\t$Opt{'5000'}\n6000\t$Opt{'6000'}\n7000\t$Opt{'7000'}\n";

if ($DATA{TRIAL} =~ /Y/ && $Company->{comsublevel} > 1) {
	print COOKIE "TRIAL\tY\n";
}
close(FILE);

$Companies->finish;
$dbh->disconnect;

print<<EOD;
Content-Type: text/html
Status: 302
Location: /cgi-bin/fpa/dashboard.pl

EOD

exit;
