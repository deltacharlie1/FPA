#!/usr/bin/perl

#  Script to run through all due recurring purchases

require "/usr/local/git/fpa/cgi/process_purchase.ph";

@Interval = ('0 day','7 day','14 day','28 day','30 day','1 month','3 month','6 month','1 year');
%Vatrate = ('S','1.2',
	    'R','1.05',
	    'Z','1');

$COOKIE->{ACCT} = '';
$COOKIE->{USER} = "auto payments";

use DBI;
$dbh = DBI->connect("DBI:mysql:fpa");

$Recpayments = $dbh->prepare("select recpayments.id as id,recpayments.acct_id as acct_id,reccus_id,date_format(recnextdate,'%d-%b-%y') as nextdate,recfreq,rectype,rectxnmethod,reccoa,recdesc,recamount,recvatrate,cusname from recpayments left join customers on (reccus_id=customers.id and recpayments.acct_id=customers.acct_id) where recnextdate <= curdate() order by acct_id");
$Recpayments->execute;
while ($Recpayment = $Recpayments->fetchrow_hashref) {

#  Get new company's VAT scheme

	if ($COOKIE->{ACCT} ne $Recpayment->{acct_id}) {
		$COOKIE->{ACCT} = $Recpayment->{acct_id};
		($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});
		$Companies = $dbh->prepare("select comvatscheme from companies where reg_id=$Reg_id and id=$Com_id");
		$Companies->execute;
		$Company = $Companies->fetchrow_hashref;
		$COOKIE->{VAT} = $Company->{comvatscheme};
	}

	$FORM{id} = "";
	$FORM{invitems} = "";
	$FORM{invtype} = "P";
	$FORM{invcoa} = $Recpayment->{reccoa};
	$FORM{invcusname} = $Recpayment->{cusname};
	$FORM{cus_id} = $Recpayment->{reccus_id};
	$FORM{invdesc} = $Recpayment->{recdesc};

	if ($COOKIE->{VAT} =~ /N/i) {
		$FORM{invtotal} = sprintf('%1.2f',$Recpayment->{recamount});
		$FORM{invvat} = '0.00';
	}
	else {
		$FORM{invtotal} = sprintf('%1.2f',$Recpayment->{recamount} / $Vatrate{$Recpayment->{recvatrate}});
		$FORM{invvat} = sprintf('%1.2f',$Recpayment->{recamount} - $FORM{invtotal});
	}
	$FORM{txnamount} = sprintf('%1.2f',$Recpayment->{recamount});
	$FORM{invprintdate} = $Recpayment->{nextdate};
	$FORM{txnmethod} = $Recpayment->{rectxnmethod};;
	$FORM{item_cat} = '';
	$FORM{invcusref} = $Recpayment->{recref};
	$FORM{vatrate} = $Vatrate{$Recpayment->{recvatrate}} - 1;

	&save_purchase('final');
	&money_out();
	&pay_purchase();

#  Finally, update the recpayment to the nextduedate

	$Sts = $dbh->do("update recpayments set recnextdate=date_add(recnextdate, interval $Interval[$Recpayment->{recfreq}]) where acct_id='$COOKIE->{ACCT}' and id=$Recpayment->{id}");

}

$Companies->finish;
$Recpayments->finish;
$dbh->disconnect;
exit;

