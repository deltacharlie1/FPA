#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to process a loan or share capitalisation

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

use CGI;
use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");
unless ($COOKIE->{NO_ADS}) {
	require "/usr/local/git/fpa/cgi/display_adverts.ph";
	&display_adverts();
}


$Data = new CGI;
%FORM = $Data->Vars;

while (( $Key,$Value) = each %FORM) {

#  Remove any bad characters

	$Value =~ tr/\\//d;
	$Value =~ s/\'/\\\'/g;
	$FORM{$Key} = $Value;
# warn "$Key = $Value\n";

}
# exit;

#  Do some basic validation

$Errs = "";

unless ($FORM{amtpaid} =~ /^\d+?\.?\d?\d$/) { $Errs .= "<li>You must enter an Amount in a proper currency form (n.nn)</li>"; }
if ($FORM{paytype} =~ /I/i) {
	unless ($FORM{rmks}) { $Errs .= "<li>You must enter a Remark describing the Receipt</li>\n"; }
}
else {
	unless ($FORM{rmks}) { $Errs .= "<li>You must enter a Remark describing the Payment</li>\n"; }
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
		$Loan_text = "received";
		$Loan_type = "income adj";

		$Acctype{2300} = "Loan Increase";
		$Acctype{3000} = "Increase in Share Capital";
		$Acctype{4300} = "Un-specified Income";
	}
	else {
		$Loan_direction = "expense";
		$Loan_text = "paid";
		$Loan_type = "expense adj";

		$Acctype{1000} = "Asset Depreciation";
		$Acctype{2300} = "Loan Repayment";
		$Acctype{3000} = "Repayment of Share Capital";
		$Acctype{6000} = "Un-specified Expense";
		$Acctype{3050} = "Dividend";
		$Acctype{6600} = "Corporation Tax";
		$Acctype{7500} = "Wages";
		$Acctype{7600} = "Payroll Taxes";
	}

	$Txntype{1200} = "Bank Transfer";
	$Txntype{1300} = "Cash";
	$Txntype{1310} = "Cheque";
	$Txntype{3100} = "Capital Account";

#  Get the next transaction no

        ($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});
        $Companies = $dbh->prepare("select comnexttxn from companies where reg_id=$Reg_id and id=$Com_id");
        $Companies->execute;
        @Company = $Companies->fetchrow;
        $Companies->finish;
        
        $FORM{txnno} = $Company[0];
        $Sts = $dbh->do("update companies set comnexttxn=comnexttxn+1 where reg_id=$Reg_id and id=$Com_id");

	if ($FORM{loantype} =~ /I/i) {		#  This is money in

#  Create the transaction record

		$Sts = $dbh->do("insert into transactions (acct_id,txncusname,txnmethod,txnamount,txndate,txntxntype,txnremarks,txntxnno) values ('$COOKIE->{ACCT}','Acct Adjustment','$FORM{paymethod}','$FORM{amtpaid}',str_to_date('$FORM{txndate}','%d-%b-%y'),'$Loan_direction','$FORM{rmks}','$FORM{txnno}')");
		$New_txn_id = $dbh->last_insert_id(undef, undef, qw(transactions undef));

#  First add amount to bank/cash account

		$Sts = $dbh->do("update coas set coabalance=coabalance + '$FORM{amtpaid}' where acct_id='$COOKIE->{ACCT}' and coanominalcode='$FORM{paymethod}'");
	        $Sts = $dbh->do("insert into nominals (acct_id,link_id,nomtype,nomcode,nomamount,nomdate) values ('$COOKIE->{ACCT}',$New_txn_id,'T','$FORM{paymethod}','$FORM{amtpaid}',str_to_date('$FORM{txndate}','%d-%b-%y'))");

#  If this is a repayment of loan then subract amount from long term liabilities, else add to other account

		if ($FORM{paytype} =~ /2300/) {
			$Txnamt = 0 - $FORM{amtpaid};
		}
		else {
			$Txnamt = $FORM{amtpaid};
		}

		$Sts = $dbh->do("update coas set coabalance=coabalance + '$Txnamt' where acct_id='$COOKIE->{ACCT}' and coanominalcode='$FORM{paytype}'");
	        $Sts = $dbh->do("insert into nominals (acct_id,link_id,nomtype,nomcode,nomamount,nomdate) values ('$COOKIE->{ACCT}',$New_txn_id,'T','$FORM{paytype}','$Txnamt',str_to_date('$FORM{txndate}','%d-%b-%y'))");

#  write the audit trail log

		$FORM{amtpaid} =~ tr/-//d;

		$Sts = $dbh->do("insert into audit_trails (acct_id,link_id,audtype,audaction,audtext,auduser) values ('$COOKIE->{ACCT}',$New_txn_id,'transactions','$Loan_type','$Acctype{$FORM{paytype}} of &pound;$FORM{amtpaid} $Loan_text $FORM{name}','$COOKIE->{USER}')");
	}
	else {					#  This is money out

#  Fix the paymethod for depreciation

		if ($FORM{paytype} =~ /1000/) {
			$FORM{paymethod} = "3100";	#  Retained Earnings
		}

		$FORM{amtpaid} = 0 - $FORM{amtpaid};	#  Reverse the sign of the amount

#  Create the transaction record

		$Sts = $dbh->do("insert into transactions (acct_id,txncusname,txnmethod,txnamount,txndate,txntxntype,txnremarks,txntxnno) values ('$COOKIE->{ACCT}','Acct Adjustment','$FORM{paymethod}','$FORM{amtpaid}',str_to_date('$FORM{txndate}','%d-%b-%y'),'$Loan_direction','$FORM{rmks}','$FORM{txnno}')");
		$New_txn_id = $dbh->last_insert_id(undef, undef, qw(transactions undef));

#  First deduct amount to bank/cash account

		$Sts = $dbh->do("update coas set coabalance=coabalance + '$FORM{amtpaid}' where acct_id='$COOKIE->{ACCT}' and coanominalcode='$FORM{paymethod}'");
	        $Sts = $dbh->do("insert into nominals (acct_id,link_id,nomtype,nomcode,nomamount,nomdate) values ('$COOKIE->{ACCT}',$New_txn_id,'T','$FORM{paymethod}','$FORM{amtpaid}',str_to_date('$FORM{txndate}','%d-%b-%y'))");

#  If this is a repayment of loan then add amount from long term liabilities, else subtract to other account

		if ($FORM{paytype} !~ /3000/) {
			$Txnamt = 0 - $FORM{amtpaid};
		}
		else {
			$Txnamt = $FORM{amtpaid};
		}

		$Sts = $dbh->do("update coas set coabalance=coabalance + '$Txnamt' where acct_id='$COOKIE->{ACCT}' and coanominalcode='$FORM{paytype}'");
	        $Sts = $dbh->do("insert into nominals (acct_id,link_id,nomtype,nomcode,nomamount,nomdate) values ('$COOKIE->{ACCT}',$New_txn_id,'T','$FORM{paytype}','$Txnamt',str_to_date('$FORM{txndate}','%d-%b-%y'))");

#  write the audit trail log

		$FORM{amtpaid} =~ tr/-//d;

		$Sts = $dbh->do("insert into audit_trails (acct_id,link_id,audtype,audaction,audtext,auduser) values ('$COOKIE->{ACCT}',$New_txn_id,'transactions','$Loan_type','$Acctype{$FORM{paytype}} of &pound;$FORM{amtpaid} $Loan_text $FORM{name}','$COOKIE->{USER}')");

	}

	print<<EOD;
Content-Type: text/plain

OK-adjustments.pl-
EOD
}
$dbh->disconnect;
exit;
