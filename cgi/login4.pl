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

$Companies = $dbh->prepare("select comname,comcompleted,comvatscheme,comexpid,comyearend,frsrate,comvatqstart,comvatmsgdue,comyearendmsgdue,datediff(comvatmsgdue,now()),datediff(comyearend,now()),if(comfree>now(),'1',''),if(comno_ads>now(),'1',''),if(comrep_invs>now(),'1',''),if(comstmts>now(),'1',''),comuplds,if(compt_logo>now(),'1',''),if(comhmrc>now(),'1',''),comsuppt,comadd_user,comcis,combusiness from companies left join market_sectors on (combusiness=market_sectors.id) where companies.id=$Reg_com[1] and reg_id=$Reg_com[0]");
$Companies->execute;
@Company = $Companies->fetchrow;
$Companies->finish;

$Company[6] =~ s/(\d+)-(\d+)-(\d+)/$1,$2 - 1,$3/;

if ($Company[2] !~ /N/i) {

	if ($Company[9] < 1) {			#  VAT Reminder due

		$Dates = $dbh->prepare("select date_add('$Company[7]', interval 3 month),date_format(date_sub('$Company[7]',interval 1 day),'%m-%y'),date_format(last_day('$Company[7]'),'%d-%b-%y')");
		$Dates->execute;
		($Company[7],$Prev_qend,$VATduedate) = $Dates->fetchrow;
		$Dates->finish;

#  Update comvatmesgdue and comvatreminder

		$Sts = $dbh->do("update companies set comvatmsgdue='$Company[7]',comvatreminder='1' where reg_id=$Reg_com[0] and id=$Reg_com[1]");

#  Write reminder message

		$Sts = $dbh->do("insert into reminders (acct_id,remtext,remcode,remgrade,remstartdate,remenddate) values ('$Reg_com[0]+$Reg_com[1]','VAT return due by $VATduedate','VATR','H',now(),'2099-01-01')");

	}
}

$ACCESS = $COOKIE->{PLAN} || $Company[12];

#############  Similar processing for Year End   ######################

if ($Company[10] < 0) {

	$Sts = $dbh->do("update companies set comyearendmsgdue=date_add(comyearend,interval 8 month),comyearend=date_add(comyearend,interval 1 year) where reg_id=$Reg_com[0] and id=$Reg_com[1]");

#  Add a couple of reminders

		$Dates = $dbh->prepare("select date_format(date_add('$Company[4]', interval 1 month),'%d-%b-%y'),date_format(date_add('$Company[4]',interval 10 month),'%d-%b-%y')");
		$Dates->execute;
		@Annual_date = $Dates->fetchrow;
		$Dates->finish;

		$Sts = $dbh->do("insert into reminders (acct_id,remtext,remcode,remgrade,remstartdate,remenddate) values ('$Reg_com[0]+$Reg_com[1]','Year End Procedures need to be completed.  Please <a href=\"/cgi-bin/fpa/yearend_cleardown.pl\">click here</a> to do this.','YRN','H',now(),'2099-01-01')");
		$Sts = $dbh->do("insert into reminders (acct_id,remtext,remcode,remgrade,remstartdate,remenddate) values ('$Reg_com[0]+$Reg_com[1]','Annual return (probably) due by $Annual_date[0]','GEN','N',now(),'2099-01-01')");
		$Sts = $dbh->do("insert into reminders (acct_id,remtext,remcode,remgrade,remstartdate,remenddate) values ('$Reg_com[0]+$Reg_com[1]','Accounts due by $Annual_date[1]','GEN','N',now(),'2099-01-01')");

}

#  Get the User defined account codes

$Coas = $dbh->prepare("select coanominalcode,coadesc,coagroup from coas where acct_id='$Reg_com[0]+$Reg_com[1]' and coagroup=? order by coanominalcode");
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

#  Set the correct FRS percentage

$Company[5] = sprintf("%1.3f",$Company[5]/100);

use Digest;
$SHA1_hash = Digest->new("SHA-1");
$SHA1_hash->add($Cookie);
$Cookie = $SHA1_hash->hexdigest;

$IP_Addr = $ENV{'REMOTE_ADDR'};
open(COOKIE,">/projects/tmp/$Cookie");
print COOKIE "IP\t$IP_Addr\nACCT\t$Reg_com[0]+$Reg_com[1]\nBACCT\t$Reg_com[0]+$Reg_com[1]\nID\t$COOKIE->{ID}\nPWD\t$COOKIE->{PWD}\nPLAN\t$COOKIE->{PLAN}\nVAT\t$Company[2]\nYEAREND\t$Company[4]\nUSER\t$User\nEXP\t$Company[3]\nFRS\t$Company[5]\nMIN\t$Company[6]\nMENU\t$COOKIE->{MENU}\nTAG\t$Company[0]\nBTAG\t$Company[0]\nACCESS\t$ACCESS\nNO_ADS\t$Company[12]\nREP_INVS\t$Company[13]\nSTMTS\t$Company[14]\nUPLDS\t$Company[15]\nPT_LOGO\t$Company[16]\nHMRC\t$Company[17]\nSUPPT\t$Company[18]\nCOOKIE\t$Cookie\nDB\tfpa\nADDU\t$Company[19]\nPREFS\t$COOKIE->{PREFS}\nCIS\t$Company[20]\nBUS\t$Company[21]\n4300\t$Opt{'4300'}\n5000\t$Opt{'5000'}\n6000\t$Opt{'6000'}\n7000\t$Opt{'7000'}\n";

close(COOKIE);
$COOKIE->{ACCT} = "$Reg_com[0]+$Reg_com[1]";

#  Update the visitcount

$Regs = $dbh->do("update registrations set reglastlogindate=now(),regvisitcount=regvisitcount + 1 where reg_id=$Reg_com[0]");

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
unless ($Company[1]) {
	$Href = "company_details.pl";
}
if ($Multi) {
	print<<EOD;
Content-Type: text/plain
Set-Cookie: fpa-cookie=$Cookie; path=/;
Set-Cookie: fpa-comname=$Company[0]; path=/;
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
Set-Cookie: fpa-comname=$Company[0]; path=/;
Set-Cookie: fpa-next_advert=0; path=/;
Set-Cookie: fpa-last_advert=12; path=/;

XqQsOK-$Href

EOD
}
$Reg_coms->finish;
$dbh->disconnect;
exit;
