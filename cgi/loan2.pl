#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to process a loan or share capitalisation

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
# print FILE "$Key = $Value\n";

}
# exit;

#  Do some basic validation

$Errs = "";

unless ($FORM{amtpaid} =~ /^\d+\.\d\d$/) { $Errs .= "<li>You must enter an Amount in a proper currency form (n.nn)</li>"; }
if ($FORM{paytype} =~ /I/i) {
	unless ($FORM{name}) { $Errs .= "<li>You must enter the Benfactor's name</li>\n"; }
}
else {
	unless ($FORM{name}) { $Errs .= "<li>You must enter the Benfeficiary's name</li>\n"; }
}

if ($Errs) {
	print<<EOD;
Content-Type: text/plain

You have the following error(s):-<ol>$Errs</ol>Please correct them before re-submitting
EOD
}
else {
	
#  If this transaction is a Loan/share increase
	my $Loan_direction,$Loan_text,$Loan_type;
	if ($FORM{loantype} =~ /I/i) {		#  Loan Increase
		$Loan_direction = "income";
		$Loan_text = "received from";
	}
	else {
		$Loan_direction = "expense";
		$Loan_text = "repaid to";
	}
	if ($FORM{paytype} =~ /loan/i) {
		$Loan_type = "Loan";
	}
	else {
		$Loan_type = "Share";
	}

#  Get the next transaction no

        ($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});
        $Companies = $dbh->prepare("select comnexttxn from companies where reg_id=$Reg_id and id=$Com_id");
        $Companies->execute;
        @Company = $Companies->fetchrow;
        $Companies->finish;
        
        $FORM{txnno} = $Company[0];
        $Sts = $dbh->do("update companies set comnexttxn=comnexttxn+1 where reg_id=$Reg_id and id=$Com_id");

#  Create the transaction record

	$Sts = $dbh->do("insert into transactions (acct_id,txncusname,txnmethod,txnamount,txndate,txntxntype,txnremarks,txntxnno) values ('$COOKIE->{ACCT}','$FORM{name}','$FORM{paymethod}','$FORM{amtpaid}',str_to_date('$FORM{txndate}','%d-%b-%y'),'$Loan_direction','$FORM{rmks}','$FORM{txnno}')");
	$New_txn_id = $dbh->last_insert_id(undef, undef, qw(transactions undef));

#  write the audit trail log

	$Sts = $dbh->do("insert into audit_trails (acct_id,link_id,audtype,audaction,audtext) values ('$COOKIE->{ACCT}',$New_txn_id,'transactions','$Loan_type','$Loan_type value of $FORM{amtpaid} $Loan_text $FORM{name}')");

#  Update the relevant liabilities nominal code 

	if ($FORM{loantype} =~ /I/i) {	#  increase
		if ($FORM{paytype} =~ /loan/i) {
			$Sts = $dbh->do("update coas set coabalance=coabalance + '$FORM{amtpaid}' where acct_id='$COOKIE->{ACCT}' and coanominalcode='2300'");
		        $Sts = $dbh->do("insert into nominals (acct_id,link_id,nomtype,nomcode,nomamount,nomdate) values ('$COOKIE->{ACCT}',$New_txn_id,'T','2300','$FORM{amtpaid}',str_to_date('$FORM{txndate}','%d-%b-%y'))");

		}
		else {
			$Sts = $dbh->do("update coas set coabalance=coabalance + '$FORM{amtpaid}' where acct_id='$COOKIE->{ACCT}' and coanominalcode='3000'");
		        $Sts = $dbh->do("insert into nominals (acct_id,link_id,nomtype,nomcode,nomamount,nomdate) values ('$COOKIE->{ACCT}',$New_txn_id,'T','3000','$FORM{amtpaid}',str_to_date('$FORM{txndate}','%d-%b-%y'))");
		}
	}
	else {				#  repayment
		if ($FORM{paytype} =~ /loan/i) {
			$Sts = $dbh->do("update coas set coabalance=coabalance - '$FORM{amtpaid}' where acct_id='$COOKIE->{ACCT}' and coanominalcode='2300'");
		        $Sts = $dbh->do("insert into nominals (acct_id,link_id,nomtype,nomcode,nomamount,nomdate) values ('$COOKIE->{ACCT}',$New_txn_id,'T','2300','-$FORM{amtpaid}',str_to_date('$FORM{txndate}','%d-%b-%y'))");
		}
		else {
			$Sts = $dbh->do("update coas set coabalance=coabalance - '$FORM{amtpaid}' where acct_id='$COOKIE->{ACCT}' and coanominalcode='3000'");
		        $Sts = $dbh->do("insert into nominals (acct_id,link_id,nomtype,nomcode,nomamount,nomdate) values ('$COOKIE->{ACCT}',$New_txn_id,'T','3000','-$FORM{amtpaid}',str_to_date('$FORM{txndate}','%d-%b-%y'))");
		}
	}

#  ... and then update the relevant Assets nominal code


	if ($FORM{loantype} =~ /I/i) {	#  increase
		if ($FORM{paytype} =~ /cash/i) {
			$Sts = $dbh->do("update coas set coabalance=coabalance + '$FORM{amtpaid}' where acct_id='$COOKIE->{ACCT}' and coanominalcode='1300'");
		        $Sts = $dbh->do("insert into nominals (acct_id,link_id,nomtype,nomcode,nomamount,nomdate) values ('$COOKIE->{ACCT}',$New_txn_id,'T','1300','$FORM{amtpaid}',str_to_date('$FORM{txndate}','%d-%b-%y'))");
		}
		else {
			$Sts = $dbh->do("update coas set coabalance=coabalance + '$FORM{amtpaid}' where acct_id='$COOKIE->{ACCT}' and coanominalcode='1200'");
		        $Sts = $dbh->do("insert into nominals (acct_id,link_id,nomtype,nomcode,nomamount,nomdate) values ('$COOKIE->{ACCT}',$New_txn_id,'T','1200','$FORM{amtpaid}',str_to_date('$FORM{txndate}','%d-%b-%y'))");
		}
	}
	else {				#  repayment
		if ($FORM{paytype} =~ /loan/i) {
			$Sts = $dbh->do("update coas set coabalance=coabalance - '$FORM{amtpaid}' where acct_id='$COOKIE->{ACCT}' and coanominalcode='1300'");
		        $Sts = $dbh->do("insert into nominals (acct_id,link_id,nomtype,nomcode,nomamount,nomdate) values ('$COOKIE->{ACCT}',$New_txn_id,'T',1300','-$FORM{amtpaid}',str_to_date('$FORM{txndate}','%d-%b-%y'))");
		}
		else {
			$Sts = $dbh->do("update coas set coabalance=coabalance - '$FORM{amtpaid}' where acct_id='$COOKIE->{ACCT}' and coanominalcode='1200'");
		        $Sts = $dbh->do("insert into nominals (acct_id,link_id,nomtype,nomcode,nomamount,nomdate) values ('$COOKIE->{ACCT}',$New_txn_id,'T','1200','-$FORM{amtpaid}',str_to_date('$FORM{txndate}','%d-%b-%y'))");
		}
	}

	print<<EOD;
Content-Type: text/plain

OK-company_details.pl-
EOD
}
$dbh->disconnect;
exit;
