#!/usr/bin/perl

#  Script to create a bank interest/charges transaction

######################################################################################################
#                                                                                                    #
#             NOTE   -  Do not change txncusname of 'Bank Payment' as this is used                   #
#                       by the data dump program to determine bank transactions                      #
#                                                                                                    #
######################################################################################################


use CGI;

$ACCESS_LEVEL = 1;

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

$Data = new CGI;
%FORM = $Data->Vars;

while (( $Key,$Value) = each %FORM) {

#  Remove any bad characters

        $Value =~ tr/\\//d;
        $Value =~ s/\'/\\\'/g;
        $FORM{$Key} = $Value;
}

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");
unless ($COOKIE->{NO_ADS}) {
	require "/usr/local/git/fpa/cgi/display_adverts.ph";
	&display_adverts();
}


if ($FORM{thisint}) {

#  Set the date if not already set

	if ($FORM{thisintdate}) {
		$Date = "str_to_date('$FORM{thisintdate}','%d-%b-%y')";
	}
	else {
		$Date = "now()";
	}

#  Get the next transaction no

        ($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});
        $Companies = $dbh->prepare("select comnexttxn from companies where reg_id=$Reg_id and id=$Com_id");
        $Companies->execute;
        @Company = $Companies->fetchrow;
        $Companies->finish;

        $FORM{txnno} = $Company[0];
        $Sts = $dbh->do("update companies set comnexttxn=comnexttxn+1 where reg_id=$Reg_id and id=$Com_id");

#  create a dummy invoice (invoice # = unlisted)  -  Not sure that his is required

	$Sts = $dbh->do("insert into invoices (acct_id,invinvoiceno,invdesc,invcusregion,invcoa,invtotal,invpaid,invprintdate,invstatus,invstatuscode,invtype) values ('$COOKIE->{ACCT}','unlisted','Bank Interest','UK','4300','$FORM{thisint}','$FORM{thisint}',$Date,'Bank','2','BI')");
       $New_inv_id = $dbh->last_insert_id(undef, undef, qw(invoices undef));

#  create a transaction record

	$Sts = $dbh->do("insert into transactions (acct_id,txncusname,link_id,txnmethod,txnamount,txndate,txntxntype,txnremarks,txntxnno) values ('$COOKIE->{ACCT}','Bank Payment',$New_inv_id,'$FORM{txnmethod}','$FORM{thisint}',$Date,'bankint','Interest','$FORM{txnno}')");
        $New_txn_id = $dbh->last_insert_id(undef, undef, qw(transactions undef));

#  Create an inv_txn record

        $Sts = $dbh->do("insert into inv_txns (acct_id,txn_id,inv_id,itnet,itvat,itdate,itmethod,itinvoiceno,ittxnno) values ('$COOKIE->{ACCT}',$New_txn_id,$New_inv_id,'$FORM{thisint}','0',$Date,'$FORM{txnmethod}','unlisted','$FORM{txnno}')");

#  update nominal codes for bank/cash/cheque and customer unallocated balance

#  Bank

        $Sts = $dbh->do("update coas set coabalance=coabalance + '$FORM{thisint}' where acct_id='$COOKIE->{ACCT}' and coanominalcode='$FORM{txnmethod}'");
	$Sts = $dbh->do("insert into nominals (acct_id,link_id,nomtype,nomcode,nomamount,nomdate) values ('$COOKIE->{ACCT}',$New_txn_id,'T','$FORM{txnmethod}','$FORM{thisint}',$Date)");

#  Other Income

        $Sts = $dbh->do("update coas set coabalance=coabalance + '$FORM{thisint}' where acct_id='$COOKIE->{ACCT}' and coanominalcode='4300'");
	$Sts = $dbh->do("insert into nominals (acct_id,link_id,nomtype,nomcode,nomamount,nomdate) values ('$COOKIE->{ACCT}',$New_txn_id,'T','4300','$FORM{thisint}',$Date)");

#  Audit trail

        $Sts = $dbh->do("insert into audit_trails (acct_id,link_id,audtype,audaction,audtext,auduser) values ('$COOKIE->{ACCT}',$New_txn_id,'transactions','bank','Bank Interest of &pound;$FORM{thisint} received','$COOKIE->{USER}')");

}
if ($FORM{thisch}) {

#  Set the date if not already set

	if ($FORM{thischdate}) {
		$Date = "str_to_date('$FORM{thischdate}','%d-%b-%y')";
	}
	else {
		$Date = "now()";
	}

	$FORM{thisch} = 0 - $FORM{thisch};

#  Get the next transaction no

        ($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});
        $Companies = $dbh->prepare("select comnexttxn from companies where reg_id=$Reg_id and id=$Com_id");
        $Companies->execute;
        @Company = $Companies->fetchrow;
        $Companies->finish;
        
        $FORM{txnno} = $Company[0];
        $Sts = $dbh->do("update companies set comnexttxn=comnexttxn+1 where reg_id=$Reg_id and id=$Com_id");

#  create a dummy invoice (invoice # = unlisted)

	$Sts = $dbh->do("insert into invoices (acct_id,invinvoiceno,invdesc,invcusregion,invcoa,invtotal,invpaid,invprintdate,invstatuscode,invtype) values ('$COOKIE->{ACCT}','unlisted','Bank Charges','UK','6000','$FORM{thisch}','$FORM{thisch}',$Date,'2','BC')");
        $New_inv_id = $dbh->last_insert_id(undef, undef, qw(invoices undef));

#  create a transaction record

        $Sts = $dbh->do("insert into transactions (acct_id,link_id,txncusname,txnmethod,txnamount,txndate,txntxntype,txnremarks,txntxnno) values ('$COOKIE->{ACCT}',$New_inv_id,'Bank Payment','$FORM{txnmethod}','$FORM{thisch}',$Date,'bankexp','Charges','$FORM{txnno}')");
        $New_txn_id = $dbh->last_insert_id(undef, undef, qw(transactions undef));

#  Create an inv_txn record

        $Sts = $dbh->do("insert into inv_txns (acct_id,txn_id,inv_id,itnet,itvat,itdate,itmethod,itinvoiceno,ittxnno) values ('$COOKIE->{ACCT}',$New_txn_id,$New_inv_id,'$FORM{thisch}','0',$Date,'$FORM{txnmethod}','unlisted','$FORM{txnno}')");

#  update nominal codes for bank/cash/cheque and customer unallocated balance

#  Bank

        $Sts = $dbh->do("update coas set coabalance=coabalance + '$FORM{thisch}' where acct_id='$COOKIE->{ACCT}' and coanominalcode='$FORM{txnmethod}'");
	$Sts = $dbh->do("insert into nominals (acct_id,link_id,nomtype,nomcode,nomamount,nomdate) values ('$COOKIE->{ACCT}',$New_txn_id,'T','$FORM{txnmethod}','$FORM{thisch}',$Date)");

	$FORM{thisch} =~ tr/\-//d;

#  Other Income

        $Sts = $dbh->do("update coas set coabalance=coabalance + '$FORM{thisch}' where acct_id='$COOKIE->{ACCT}' and coanominalcode='6000'");
	$Sts = $dbh->do("insert into nominals (acct_id,link_id,nomtype,nomcode,nomamount,nomdate) values ('$COOKIE->{ACCT}',$New_txn_id,'T','6000','$FORM{thisch}',$Date)");

#  Audit trail

        $Sts = $dbh->do("insert into audit_trails (acct_id,link_id,audtype,audaction,audtext,auduser) values ('$COOKIE->{ACCT}',$New_txn_id,'transactions','bank','Bank Charges of &pound;$FORM{thisch} paid','$COOKIE->{USER}')");

}
print<<EOD;
Content-Type:text/html
Status: HTTP/1.1 204 No Content

EOD
$dbh->disconnect;
exit;
