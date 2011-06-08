#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to process cash to bank and cheques

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

use CGI;
use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");

$Data = new CGI;
%FORM = $Data->Vars;

# print "Content-Type: text/plain\n\n";

while (( $Key,$Value) = each %FORM) {

#  Remove any bad characters

	$Value =~ tr/\\//d;
	$Value =~ s/\'/\\\'/g;
	$FORM{$Key} = $Value;
# print "$Key = $Value\n";

}
# exit;

#  Do some basic validation

$Errs = "";

unless ($FORM{tframt} =~ /^-?\d+\.?\d?\d?$/) { $Errs .= "<li>$FORM{tframt} - You must enter the amount being transferred</li>\n"; }

if ($Errs) {
	print<<EOD;
Content-Type: text/plain

Errors!

$Errs
EOD
}
else {

#  Set up an associative array of the transfer details

	$Tfr{'1200'} = "Current Account";
	$Tfr{'1210'} = "Deposit Account";
	$Tfr{'1300'} = "Cash";
	$Tfr{'1310'} = "Cheques";
	$Tfr{'2010'} = "Credit Card";

#  First add up all cheques

	$Cheque_total = 0;
	$Cheque_count = 0;
	while (($Key,$Value) = each %FORM) {
		if ($Key =~ /^x/i) {		#  This is a cheque
			$Key =~ tr/x//d;	#  Strip off the leading 'x'

#  Update the cheque transaction to 'banked'

			$Sts = $dbh->do("update transactions set txnbanked='Y' where acct_id='$COOKIE->{ACCT}' and txnmethod='1310' and id=$Key");

			$Cheque_total += $Value;
			$Cheque_count++;
		}
	}

#  Get the next transaction no and enter the amoount being put in to the bank

        ($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});
        $Companies = $dbh->prepare("select comnexttxn from companies where reg_id=$Reg_id and id=$Com_id");
        $Companies->execute;
        @Company = $Companies->fetchrow;
        
        $FORM{txnno} = $Company[0];
        $Sts = $dbh->do("update companies set comnexttxn=comnexttxn+1 where reg_id=$Reg_id and id=$Com_id");

#  Bank Current Account entry (put money into bank account)

	$Sts = $dbh->do("insert into transactions (acct_id,txnamount,txndate,txnmethod,txntxntype,txncusname,txnremarks,txntxnno,txnyearend) values ('$COOKIE->{ACCT}','$FORM{tframt}' + '$Cheque_total',str_to_date('$FORM{tfrdate}','%d-%b-%y'),'1200','transfer','Cash','Cash (and cheques) to bank','$FORM{txnno}','$COOKIE->{YEAREND}')");
        $New_txn_id = $dbh->last_insert_id(undef, undef, qw(transactions undef));

#  Update the current account nominal code

	$Sts = $dbh->do("update coas set coabalance=coabalance + '$FORM{tframt}' + '$Cheque_total' where acct_id='$COOKIE->{ACCT}' and coanominalcode='1200'");
        $Sts = $dbh->do("insert into nominals (acct_id,link_id,nomtype,nomcode,nomamount,nomdate) values ('$COOKIE->{ACCT}',$New_txn_id,'T','1200','$FORM{tframt}' + '$Cheque_total',str_to_date('$FORM{tfrdate}','%d-%b-%y'))");

	if ($FORM{tframt}) {

#  Update the cash nominal code

	        $Contra_amt = 0 - $FORM{tframt};

        	$Companies = $dbh->prepare("select comnexttxn from companies where reg_id=$Reg_id and id=$Com_id");
	        $Companies->execute;
        	@Company = $Companies->fetchrow;
        
	        $FORM{txnno} = $Company[0];
        	$Sts = $dbh->do("update companies set comnexttxn=comnexttxn+1 where reg_id=$Reg_id and id=$Com_id");

	        $Sts = $dbh->do("insert into transactions (acct_id,txnamount,txndate,txnmethod,txntxntype,txncusname,txnremarks,txntxnno,txnyearend) values ('$COOKIE->{ACCT}','$Contra_amt',str_to_date('$FORM{tfrdate}','%d-%b-%y'),'1300','transfer','Cash','Cash to bank','$FORM{txnno}','$COOKIE->{YEAREND}')");
#       	 $New_txn_id = $dbh->last_insert_id(undef, undef, qw(transactions undef));


		$Sts = $dbh->do("update coas set coabalance=coabalance - '$FORM{tframt}' where acct_id='$COOKIE->{ACCT}' and coanominalcode='1300'");
        	$Sts = $dbh->do("insert into nominals (acct_id,link_id,nomtype,nomcode,nomamount,nomdate) values ('$COOKIE->{ACCT}',$New_txn_id,'T','1300','$Contra_amt',str_to_date('$FORM{tfrdate}','%d-%b-%y'))");
	}

	if ($Cheque_total) {

#  Update cheques nominal code

	        $Contra_amt = 0 - $Cheque_total;

        	$Companies = $dbh->prepare("select comnexttxn from companies where reg_id=$Reg_id and id=$Com_id");
	        $Companies->execute;
        	@Company = $Companies->fetchrow;
        
	        $FORM{txnno} = $Company[0];
        	$Sts = $dbh->do("update companies set comnexttxn=comnexttxn+1 where reg_id=$Reg_id and id=$Com_id");

	        $Sts = $dbh->do("insert into transactions (acct_id,txnamount,txndate,txnmethod,txntxntype,txncusname,txnremarks,txntxnno,txnyearend,txnbanked) values ('$COOKIE->{ACCT}','$Contra_amt',str_to_date('$FORM{tfrdate}','%d-%b-%y'),'1310','transfer','Cheque','Cash to bank (cheques)','$FORM{txnno}','$COOKIE->{YEAREND}','Y')");
#       	 $New_txn_id = $dbh->last_insert_id(undef, undef, qw(transactions undef));


		$Sts = $dbh->do("update coas set coabalance=coabalance - '$Cheque_total' where acct_id='$COOKIE->{ACCT}' and coanominalcode='1310'");
        	$Sts = $dbh->do("insert into nominals (acct_id,link_id,nomtype,nomcode,nomamount,nomdate) values ('$COOKIE->{ACCT}',$New_txn_id,'T','1310','$Contra_amt',str_to_date('$FORM{tfrdate}','%d-%b-%y'))");

#  Change the no of undeposited cheques still held

		$Sts = $dbh->do("update companies set comnocheques=comnocheques - '$Cheque_count' where  reg_id=$Reg_id and id=$Com_id");
	}

#  Create an audit trail record

        $FORM{tframt} = sprintf("%1.2f",$FORM{tframt} + $Cheque_total);
        $Cheque_total = sprintf("%1.2f",$Cheque_total);

        $Sts = $dbh->do("insert into audit_trails (acct_id,link_id,audtype,audaction,audtext,auduser) values ('$COOKIE->{ACCT}',$New_txn_id,'list_txns.pl','transfer','&pound;$FORM{tframt} (including $Cheque_count cheques totalling &pound;$Cheque_total) put in to bank','$COOKIE->{USER}')");

	print<<EOD;
Content-Type: text/plain

OK-<p style="font-weight:normal;">A total of &pound;$FORM{tframt} (including $Cheque_count cheques totalling &pound;$Cheque_total) recorded in to bank</p>
EOD
}
$Companies->finish;
$dbh->disconnect;
exit;
