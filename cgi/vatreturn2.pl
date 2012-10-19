#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to update a VAT return

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

use CGI;
use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");

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
if ($FORM{save} =~ /Filed/i) {

	$Status = "Filed";

#  Delete any reminder

	$Sts = $dbh->do("delete from reminders where acct_id='$COOKIE->{ACCT}' and remcode='VATR'");
}
else {
	$Status = "Completed";
}

if ($FORM{id} > 0) {		#  Existing record, so just update status

	$Sts = $dbh->do("update vatreturns set perstatus='$Status',perstatusdate=curdate(),perfiled=curdate() where acct_id='$COOKIE->{ACCT}' and id=$FORM{id}");

#  Write an audit trail record

        $Sts = $dbh->do("insert into audit_trails (acct_id,link_id,audtype,audaction,audtext,auduser) values ('$COOKIE->{ACCT}',$FORM{id},'vatreturn.pl','vat','VAT Return for quarter ending $Vatreturn[2] marked as $Status','$COOKIE->{USER}')");
}
else {				#  New return

#  See if this is a zero return

	if ($FORM{perbox1} + $FORM{perbox2} - $FORM{perbox4} == 0) {
		$Status = "Paid";
	}

#  insert a new Vat return record

	if ($Status =~ /Completed/i) {
        	$Sts = $dbh->do("insert into vatreturns (acct_id,perquarter,perstartdate,perenddate,perduedate,perstatus,perstatusdate,perbox1,perbox2,perbox3,perbox4,perbox5,perbox6,perbox7,perbox8,perbox9,percompleted) values ('$COOKIE->{ACCT}','$Date[0]','$Date[1]','$Date[2]','$Date[3]','$Status',now(),'$FORM{perbox1}','$FORM{perbox2}','$FORM{perbox1}'+'$FORM{perbox2}','$FORM{perbox4}','$FORM{perbox1}'+'$FORM{perbox2}'-'$FORM{perbox4}','$FORM{perbox6}','$FORM{perbox7}','$FORM{perbox8}','$FORM{perbox9}',now())");
	}
	else {
#  include Filed date

        	$Sts = $dbh->do("insert into vatreturns (acct_id,perquarter,perstartdate,perenddate,perduedate,perstatus,perstatusdate,perbox1,perbox2,perbox3,perbox4,perbox5,perbox6,perbox7,perbox8,perbox9,percompleted,perfiled) values ('$COOKIE->{ACCT}','$Date[0]','$Date[1]','$Date[2]','$Date[3]','$Status',now(),'$FORM{perbox1}','$FORM{perbox2}','$FORM{perbox1}'+'$FORM{perbox2}','$FORM{perbox4}','$FORM{perbox1}'+'$FORM{perbox2}'-'$FORM{perbox4}','$FORM{perbox6}','$FORM{perbox7}','$FORM{perbox8}','$FORM{perbox9}',now(),now())");
	}

       	$New_vat_id = $dbh->last_insert_id(undef, undef, qw(vatreturns undef));

#  Now update the vataccrual records

	$Sts = $dbh->do("update vataccruals set vr_id=$New_vat_id where acct_id='$COOKIE->{ACCT}' and acrprintdate<=str_to_date('$FORM{qend}','%d-%b-%y') and vr_id < 1");

#  Update comvatqstart to the new start date (MIN) and deduct vat return box 5 from comvatcontrol

	($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});
	$Sts = $dbh->do("update companies set comvatqstart='$Date[4]',comvatreminder='',comvatcontrol=comvatcontrol - ('$FORM{perbox1}'+'$FORM{perbox2}'-'$FORM{perbox4}') where reg_id=$Reg_id and id=$Com_id");

#  Update the Cookie File (have to read in and then write out)

	$Date[4] =~ s/(\d+)-(\d+)-(\d+)/$1,$2 - 1,$3/;

        $ENV{HTTP_COOKIE} = $ENV{HTTP_COOKIE} || "";

       	@Cookie = split(/\;/,$ENV{HTTP_COOKIE});
        foreach (@Cookie) {
       	        ($Name,$Value) = split(/\=/,$_);
               	$Name =~ s/^ //g;
                $Value =~ tr/\"//d;
       	        $Cookie{$Name} = $Value;
        }

	$Data = "";
	open(FILE,"</projects/tmp/$Cookie{'fpa-cookie'}");
	while (<FILE>) {
		if (/^MIN/) {
			$Data .= "MIN\t$Date[4]\n";
		}
		else {
			$Data .= $_;
		}
	}
	close(FILE);

	unlink("/projects/tmp/$Cookie{'fpa-cookie'}");

	open(FILE,">/projects/tmp/$Cookie{'fpa-cookie'}");
	print FILE $Data;
	close(FILE);

#  Finally, write an audit trail comment

       	$Sts = $dbh->do("insert into audit_trails (acct_id,link_id,audtype,audaction,audtext,auduser) values ('$COOKIE->{ACCT}',$New_vat_id,'vatreturn.pl','vat','VAT Return for quarter ending $Date[0] $Status','$COOKIE->{USER}')");

}
	
print<<EOD;
Content-Type: text/html
Status: 302
Location: /cgi-bin/fpa/list_vatreturns.pl

EOD
$dbh->disconnect;
exit;
