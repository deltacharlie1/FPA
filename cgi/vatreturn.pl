#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to display VAT Return form

#  VAT Return statuses are:-

#  -  Blank     - Still open for additions
#  -  Completed - The return has been completed and finalised such that no further transaction/invoices can be
#                 entered prior to the closure date
#  -  Filed     - The details have been filed with HMRC at which point a transaction record is created
#  -  Paid	- A transaction to/from HMRC has taken place and been recorded as part of the bank reconciliation process


use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");

#  Is this for an existing VAT return (ie QUERY_STRING > 0)

if ($ENV{QUERY_STRING} > 0) {

#  Yes - so just get the details fro this return

	$Vatreturns = $dbh->prepare("select id,perstatus,perquarter,date_format(perstartdate,'%d-%b-%y') as dispstart,date_format(perenddate,'%d-%b-%y') as dispend,perbox1,perbox2,perbox3,perbox4,perbox5,perbox6,perbox7,perbox8,perbox9 from vatreturns where acct_id='$COOKIE->{ACCT}' and id=$ENV{QUERY_STRING}");
	$Vatreturns->execute;
	$Vatreturn->{rows} = $Vatreturns->rows;
	$Vatreturn = $Vatreturns->fetchrow_hashref;
	$Vatreturns->finish;
}
else {

#  Not a pre-existing VAT return so ...

#  1.  Get the vat qend date and whether the vatreminder flag has been set (in which case backdate qend by 3 months)

        ($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});
	$Companies = $dbh->prepare("select comvatreminder,last_day(date_sub(comvatmsgdue,interval 4 month)) as qend1,last_day(date_sub(comvatmsgdue,interval 1 day)) as qend2,date_format(last_day(date_sub(comvatmsgdue,interval 4 month)),'%d-%b-%y') as dispend1,date_format(last_day(date_sub(comvatmsgdue,interval 1 day)),'%d-%b-%y') as dispend2,comvatmsgdue from companies where reg_id=$Reg_id and id=$Com_id");
	$Companies->execute;
	@Company = $Companies->fetchrow;
	$Companies->finish;
	if ($Company[0]) {
		$Vatreturn->{qend} = $Company[1];
		$Vatreturn->{dispend} = $Company[3];
		$Vatreturn->{perstatus} = "save";
	}
	else {
		$Vatreturn->{qend} = $Company[2];
		$Vatreturn->{dispend} = $Company[4];
		$Vatreturn->{perstatus} = "Paid";
	}

#  2.  Determine the start date (close date of last return +1 day) (or arbitary date if no previous returns)

	$Vatreturns = $dbh->prepare("select date_add(perenddate,interval 1 day),date_format(date_add(perenddate,interval 1 day),'%d-%b-%y'),last_day(date_add(perenddate,interval 3 month)),date_format(last_day(date_add(perenddate,interval 3 month)),'%d-%b-%y') from vatreturns where acct_id='$COOKIE->{ACCT}' order by id desc limit 1");
	$Vatreturns->execute;

	if ($Vatreturns->rows < 1) {

#  We don't yet have any returns so set an arbitary start date and display up until the end of the previous quarter

		$Vatreturn->{qstart} = "2005-01-01";
		$Vatreturn->{dispstart} = "Up";
	}
	else {
		@Vatreturn = $Vatreturns->fetchrow;
		$Vatreturn->{qstart} = $Vatreturn[0];
		$Vatreturn->{dispstart} = $Vatreturn[1];
		$Vatreturn->{qend} = $Vatreturn[2];
		$Vatreturn->{dispend} = $Vatreturn[3];
	}

	$Vatreturns->finish;

	$Vatreturn->{id} = "0";		#  Make sure this is treated as a new insertion

#  Set the date range for stats

	$Date_Range = "acrprintdate<='$Vatreturn->{qend}'";

#  Now get the data

        $Vataccs = $dbh->prepare("select sum(acrvat) from vataccruals where acct_id='$COOKIE->{ACCT}' and $Date_Range and vr_id < 1 and (acrnominalcode='4000' or acrnominalcode like '43%')");
        $Vataccs->execute;
        ($Vatreturn->{perbox1}) = $Vataccs->fetchrow;

        $Vataccs = $dbh->prepare("select sum(acrvat) from vataccruals where acct_id='$COOKIE->{ACCT}' and $Date_Range and vr_id < 1 and acrnominalcode='4100'");
        $Vataccs->execute;
        ($Vatreturn->{perbox2}) = $Vataccs->fetchrow;

        $Vataccs = $dbh->prepare("select sum(acrvat) from vataccruals where acct_id='$COOKIE->{ACCT}' and $Date_Range and vr_id < 1 and (acrnominalcode like '10%' or acrnominalcode like '15%' or (acrnominalcode>='5000' and acrnominalcode<'7500'))");
        $Vataccs->execute;
        ($Vatreturn->{perbox4}) = $Vataccs->fetchrow;
	$Vatreturn->{perbox4} = 0 - $Vatreturn->{perbox4};	#  because it is already a negative number

#  If Fixed Rated Scheme then show vat inclusive totals, otherwise show VAT exclusive totals

	if ($COOKIE->{VAT} =~ /F/i) {
		if ($COOKIE->{VAT} =~ /C/i) {
        		$Vataccs = $dbh->prepare("select sum(itnet+itvat) from vataccruals left join inv_txns on (acrtxn_id=inv_txns.id and vataccruals.acct_id=inv_txns.acct_id) where vataccruals.acct_id='$COOKIE->{ACCT}' and $Date_Range and vr_id < 1 and (acrnominalcode in ('4000','4100','4200') or acrnominalcode like '43%')");
		}
		else {
        		$Vataccs = $dbh->prepare("select sum(invtotal+invvat) from vataccruals left join invoices on (acrtxn_id=invoices.id and vataccruals.acct_id=invoices.acct_id) where vataccruals.acct_id='$COOKIE->{ACCT}' and $Date_Range and vr_id < 1 and (acrnominalcode in ('4000','4100','4200') or acrnominalcode like '43%')");
		}
	}
	else {
        	$Vataccs = $dbh->prepare("select sum(acrtotal) from vataccruals where acct_id='$COOKIE->{ACCT}' and $Date_Range and vr_id < 1 and (acrnominalcode in ('4000','4100','4200') or acrnominalcode like '43%')");
	}
        $Vataccs->execute;
        ($Vatreturn->{perbox6}) = $Vataccs->fetchrow;

        $Vataccs = $dbh->prepare("select sum(acrtotal) from vataccruals where acct_id='$COOKIE->{ACCT}' and $Date_Range and vr_id < 1 and (acrnominalcode like '10%' or acrnominalcode like '15%' or (acrnominalcode>='5000' and acrnominalcode<'7500'))");
        $Vataccs->execute;
        ($Vatreturn->{perbox7}) = $Vataccs->fetchrow;
        $Vatreturn->{perbox7} =~ tr/-//d;

        $Vataccs = $dbh->prepare("select sum(acrtotal) from vataccruals where acct_id='$COOKIE->{ACCT}' and $Date_Range and vr_id < 1 and acrnominalcode='4100'");
        $Vataccs->execute;
        ($Vatreturn->{perbox8}) = $Vataccs->fetchrow;

        $Vataccs = $dbh->prepare("select sum(acrtotal) from vataccruals left join invoices on (invoices.id=vataccruals.acrtxn_id and invoices.acct_id=vataccruals.acct_id)  where vataccruals.acct_id='$COOKIE->{ACCT}' and $Date_Range and vr_id < 1 and(acrnominalcode like '10%' or (acrnominalcode>='5000' and acrnominalcode<'7500')) and invcusregion='EU'");
        $Vataccs->execute;
        ($Vatreturn->{perbox9}) = $Vataccs->fetchrow;
        $Vatreturn->{perbox9} =~ tr/-//d;

        $Vataccs->finish;

	$Vatreturn->{perbox3} = $Vatreturn->{perbox1} + $Vatreturn->{perbox2};
	$Vatreturn->{perbox5} = $Vatreturn->{perbox3} - $Vatreturn->{perbox4};
}

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
        WRAPPER => 'header.tt',
});

$Vars = {
	 ads => $Adverts,
        title => 'Accounts - VAT Return',
	cookie => $COOKIE,
	focus => 'perbox1',
	vatreturn => $Vatreturn,
        javascript => '
<script type="text/javascript">
function print_list() {
   $.get("/cgi-bin/fpa/print_vatreturn.pl",$("form#form1").serialize() ,function(data) {
     $("#main").html(data);
     $("#vattabs").hide();
     $("#printtab").show();
   });
}
function calc_val(obj) {

  if (! /^\d+\.?\d?\d?/.test(obj.value)) {
    alert("Invalid Value, please correct");
  }
  else {
    var box1 = 0;
    var box2 = 0;
    var box3 = 0;
    var box4 = 0;
    var box5 = 0;

    if (document.getElementById("perbox1").value.length > 0) {
      box1 = parseFloat(document.getElementById("perbox1").value);
    }
    if (document.getElementById("perbox2").value.length > 0) {    
      box2 = parseFloat(document.getElementById("perbox2").value);
    }
    if (document.getElementById("perbox4").value.length > 0) {
      box4 = parseFloat(document.getElementById("perbox4").value);
    }

    box3 = (box1 +box2);

    box5 = (box3 - box4).toFixed(2);

    $("#box3").html(box3);
    $("#box5").html(box5);
  }
}
</script>',
};

print "Content-Type: text/html\n\n";
$tt->process('vatreturn.tt',$Vars);
$dbh->disconnect;
exit;

