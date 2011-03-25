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

if ($FORM{save} =~ /List/i) {

#  List VAT entries in simple text format

	open(TEMP,">",\$Input_file);

	$Report_date = `date +%d-%b-%y`;
	chomp($Report_date);

	$Tot_input = 0;
	$Tot_output = 0;

	$ofh = select(TEMP);
	$- = 0;
	select($ofh);

#  Set up the header

	format TEMP_TOP =
                  VAT Period:  @>>>>>>>>>>  to  @<<<<<<<<<<
$FORM{qstart},$FORM{qend}

Report Date: @<<<<<<<<<<                                       Page No: @<<<
$Report_date,$%

VAT Date    Detail                                   VAT Output  VAT Input
---------------------------------------------------------------------------
.

	format TEMP = 
@<<<<<<<<<  @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<  @>>>>>>>>  @>>>>>>>>
$Accrual[0],$Accrual[1],$Output,$Input
.

	if ($COOKIE->{VAT} =~ /S/i) {
        	$Accruals = $dbh->prepare("select date_format(acrprintdate,'%d-%b-%y') as vatdate, invcusname,invinvoiceno,acrtype,acrvat as acramt,invoices.id as inv_id from vataccruals,invoices where vataccruals.acrtxn_id=invoices.id and vataccruals.acct_id=invoices.acct_id and vr_id=$FORM{id} and vataccruals.acct_id='$COOKIE->{ACCT}' order by acrprintdate");
	}
	else {
        	$Accruals = $dbh->prepare("select date_format(acrprintdate,'%d-%b-%y') as vatdate, invcusname,invinvoiceno,acrtype,acrvat as acramt,inv_txns.inv_id as inv_id from vataccruals,inv_txns,invoices where vataccruals.acrtxn_id=inv_txns.id and vataccruals.acct_id=inv_txns.acct_id and inv_txns.inv_id=invoices.id and inv_txns.acct_id=invoices.acct_id and vr_id=$FORM{id} and vataccruals.acct_id='$COOKIE->{ACCT}' order by acrprintdate");
	}

        $Accruals->execute;
	while (@Accrual = $Accruals->fetchrow) {
		$Accrual[4] =~ tr/-//d;
		if ($Accrual[4] > 0) {
			$Accrual[1] = substr($Accrual[1],0,21)." (Invoice - $Accrual[2])";
			if ($Accrual[3] =~ /P/i) {
				$Input = $Accrual[4];
				$Output = "";
				$Tot_input += $Input;
			}
			else {
				$Output = $Accrual[4];
				$Input = "";
				$Tot_output += $Output;
			}
			write TEMP;
		}
	}
	print TEMP "---------------------------------------------------------------------------\n";
	printf TEMP "            Totals                                    %9.2f  %9.2f\n",$Tot_output,$Tot_input;
	print TEMP "===========================================================================\n";

	close(TEMP);
	use Template;
	$tt = Template->new({
        	INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
	        WRAPPER => 'header.tt',
	});
	print "Content-Type:text/html\n\n";
	$Vars = { cookie => $COOKIE,
	  data => $Input_file
	};
	$tt->process('print_listing.tt',$Vars);

	$Accruals->finish;
}
else {
	if ($FORM{save} =~ /Filed/i) {

		$Status = "Filed";

#  Delete any reminder

		$Sts = $dbh->do("delete from reminders where acct_id='$COOKIE->{ACCT}' and remcode='VATR'");
	}
	else {
		$Status = "Completed";
	}

warn "Process VAT return\n";

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
Status: 301
Location: /cgi-bin/fpa/list_vatreturns.pl

EOD
}
$dbh->disconnect;
exit;
