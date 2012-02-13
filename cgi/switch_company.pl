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

if ($ACCESS > 1) {

#  Get the User defined account codes

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
}
else {
	$Opt{'4300'} = "<option value='4300'>Other Income</option>";
	$Opt{'5000'} = "<option value='5000'>Cost of Sales</option>";
	$Opt{'6000'} = "<option value='6000' selected='seleted'>Other Expenses</option>";
	$Opt{'7000'} = "<option value='7000'>Fixed Overheads</option>";
}


#  Set the correct FRS percentage

$Company->{frsrate} = sprintf("%1.3f",$Company->{frsrate}/100);

$IP_Addr = $ENV{'REMOTE_ADDR'};
open(COOKIE,">/projects/tmp/$Cookie{'fpa-cookie'}");
print COOKIE "IP\t$IP_Addr\nACCT\t$New_reg_id+$New_com_id\nBACCT\t$DATA{BACCT}\nID\t$DATA{ID}\nPWD\t$DATA{PWD}\nPLAN\t$DATA{PLAN}\nVAT\t$Company->{comvatscheme}\nYEAREND\t$Company->{comyearend}\nUSER\t$DATA{USER}\nEXP\t$Company->{comexpid}\nFRS\t$Company->{frsrate}\nMIN\t$Company->{comvatstart}\nMENU\t$DATA{MENU}\nTAG\t$Company->{comname}\nBTAG\t$DATA{BTAG}\nACCESS\t$DATA{ACCESS}\nUPLDS\t$DATA{UPLDS}}\nPT_LOGO\t$Company->{pt_logo}\nCOOKIE\t$Cookie\nDB\t$DATA{DB}\nADDU\t$Company->{comadd_user}\nPREFS\t$COOKIE->{PREFS}\nCIS\t$Company->{comcis}\nBUS\t$DATA{BUS}\n4300\t$Opt{'4300'}\n5000\t$Opt{'5000'}\n6000\t$Opt{'6000'}\n7000\t$Opt{'7000'}\n";

close(FILE);

$Companies->finish;
$dbh->disconnect;

print<<EOD;
Content-Type: text/html
Status: 301
Location: /cgi-bin/fpa/dashboard.pl

EOD

exit;
#!/usr/bin/perl

#  login script part 4 - set up the proper cookie file and display the opening screen

use DBI;
$dbh = DBI->connect("DBI:mysql:fpa");

# ($Offset,$Multi) = split(/\?/,$ENV{QUERY_STRING});
@Cookie = split(/\;/,$ENV{HTTP_COOKIE});
foreach (@Cookie) {
        ($Name,$Value) = split(/\=/,$_);
        $Name =~ s/^ //g;
        $Value =~ tr/\"//d;
         $Cookie{$Name} = $Value;
}
open(COOKIE,"/projects/tmp/$Cookie{'fpa-cookie'}");
while (<COOKIE>) {
	chomp($_);
	($Name,$Value) = split(/\t/,$_);
	$COOKIE->{$Name} = $Value;
}
close(COOKIE);

unlink("/projects/tmp/$Cookie{'fpa-cookie'}");

$Reg_coms = $dbh->prepare("select reg2_id,com_id,comname,mlgdefmenu from reg_coms where reg1_id=$COOKIE->{REG} order by id");
$Reg_coms->execute;

$User = $COOKIE->{ID};
$User =~ s/^(.*?)\@.*/$1/;
@Reg_com = $Reg_coms->fetchrow;		#  Get the first entry which should be the original

$Cookie = $Reg[2].$$;

close(COOKIE);
$COOKIE->{ACCT} = "$New_reg_id+$New_com_id";

#  Update the visitcount

$Regs = $dbh->do("update registrations set reglastlogindate=now(),regvisitcount=regvisitcount + 1 where reg_id=$New_reg_id");

#  Update the status of any invoices

$Invoices = $dbh->prepare("select to_days(invprintdate),to_days(invduedate),to_days(now()),invtotal,invvat,invpaid,invpaidvat,id from invoices where invstatuscode > '2' and not isnull(invduedate) and acct_id='$COOKIE->{ACCT}'");
$Invoices->execute;
while (@Invoice = $Invoices->fetchrow) {

	if ($Invoice[1] < $Invoice[2]) {
		$Sts = $dbh->do("update invoices set invstatus='Overdue',invstatuscode='9' where id=$Invoice[7] and acct_id='$COOKIE->{ACCT}'");
	}
	elsif (($Invoice[1] - $Invoice[2]) < ($Invoice[1] - $Invoice[0]) * 0.7) {
		$Sts = $dbh->do("update invoices set invstatus='Due',invstatuscode='6' where id=$Invoice[7] and acct_id='$COOKIE->{ACCT}'");
	}
}
$Invoices->finish;

#  Check to see if the company details and account details have been completed

$Href = $Reg_com[3];
unless ($Company->{comcompleted}) {
	$Href = "company_details.pl";
}
if ($Multi) {
	print<<EOD;
Content-Type: text/plain
Set-Cookie: fpa-cookie=$Cookie; path=/;
Set-Cookie: fpa-comname=$Company->{comname}; path=/;
Set-Cookie: fpa-next_advert=0; path=/;
Set-Cookie: fpa-last_advert=12; path=/;
Status: 301
Location: /cgi-bin/fpa/$Href

EOD
}
else {
	print<<EOD;
Content-Type: text/plain
Set-Cookie: fpa-cookie=$Cookie; path=/;
Set-Cookie: fpa-comname=$Company->{comname}; path=/;
Set-Cookie: fpa-next_advert=0; path=/;
Set-Cookie: fpa-last_advert=12; path=/;

XqQsOK-$Href

EOD
}
$Reg_coms->finish;
$dbh->disconnect;
exit;
