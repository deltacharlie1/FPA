#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to update opening balances

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

}

#  check to ensure that opening balances have not already been entered

($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});

$Companies = $dbh->prepare("select comacccompleted from companies where reg_id=$Reg_id and id=$Com_id");
$Companies->execute;
@Company = $Companies->fetchrow;

#  Do some basic validation

$Errs = "";

if ($FORM{x1300} && $FORM{x1300} !~ /^-?\d+\.?\d?\d?$/) { $Errs .= "<li>Invalid Cash on Hand amount</li>\n"}
if ($FORM{x1200} && $FORM{x1200} !~ /^-?\d+\.?\d?\d?$/) { $Errs .= "<li>Invalid Current Account amount</li>\n"; }
if ($FORM{cstmt} && $FORM{cstmt} !~ /^-?\d+$/) { $Errs .= "<li>Invalid Current Account Statement Number</li>\n"; }
if ($FORM{x1210} && $FORM{x1210} !~ /^-?\d+\.?\d?\d?$/) { $Errs .= "<li>Invalid Deposit Account amount</li>\n"; }
if ($FORM{dstmt} && $FORM{dstmt} !~ /^-?\d+$/) { $Errs .= "<li>Invalid Current Account Statement Number</li>\n"; }
if ($FORM{x2010} && $FORM{x2010} !~ /^-?\d+\.?\d?\d?$/) { $Errs .= "<li>Invalid Credit Card amount</li>\n"; }
if ($FORM{x1000} && $FORM{x1000} !~ /^-?\d+\.?\d?\d?$/) { $Errs .= "<li>Invalid Current Assets amount</li>\n"; }
if ($FORM{x1100} && $FORM{x1100} !~ /^-?\d+\.?\d?\d?$/) { $Errs .= "<li>Invalid Debtors amount</li>\n"; }
if ($FORM{x2000} && $FORM{x2000} !~ /^-?\d+\.?\d?\d?$/) { $Errs .= "<li>Invalid Creditors amount</li>\n"; }
if ($FORM{xvat} && $FORM{xvat} !~ /^-?\d+\.?\d?\d?$/) { $Errs .= "<li>Invalid VAT Owed amount</li>\n"; }

if ($Errs) {
	print<<EOD;
Content-Type: text/plain

Errors!

You have the following errors:-
<ol>$Errs</ol>
Please correct them and re-submit
EOD
}
else {
	($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});

	$Acctype{1200} = "Current Account";
	$Acctype{1210} = "Deposit Account";
	$Acctype{2010} = "Credit Card";
	$Acctype{1000} = "Fixed Assets";
	$Acctype{3100} = "Long Term Liabilities";

	$Retained_earnings = 0;
	if ($FORM{cdate}) {
		$Start_date = "str_to_date('$FORM{cdate}','%d-%b-%y')";
	}
	else {
		$Start_date = "now()";
	}

#  Determine whether this is a new balance or an adjustment (is there an existing statement)

	$Stmts = $dbh->prepare("select * from statements where acct_id='$COOKIE->{ACCT}' and stanotxns='-1'");
	$Stmts->execute;
	if ($Stmts->rows > 0) {
		$Adjustment = "adjustment for";
	}
	else {
		$Adjustment = "for";
	}

	while (($Key,$Value) = each %FORM) {
		if ($Value && $Key =~ /^x\d\d\d\d/) {
			$Key =~ s/^x//;
#  Add a transaction

			$Companies = $dbh->prepare("select comnexttxn from companies where reg_id=$Reg_id and id=$Com_id");
			$Companies->execute;
			@Company = $Companies->fetchrow;
	
		        $Sts = $dbh->do("insert into transactions (acct_id,txncusname,txnmethod,txnamount,txndate,txntxntype,txnremarks,txntxnno,txnselected) values ('$COOKIE->{ACCT}','Opening Balance $Adjustment $Acctype{$Key}','$Key','$Value',$Start_date,'income','$Acctype{$Key}','$Company[0]','F')");
		        $New_txn_id = $dbh->last_insert_id(undef, undef, qw(transactions undef));

			$Sts = $dbh->do("update companies set comnexttxn=comnexttxn+1 where reg_id=$Reg_id and id=$Com_id");

			$Sts = $dbh->do("update coas set coabalance=coabalance + '$Value' where acct_id='$COOKIE->{ACCT}' and coanominalcode='$Key'");

			if ($Key =~ /2010|3100/) {
				$Retained_earnings -= $Value;
				$Sts = $dbh->do("insert into nominals (acct_id,link_id,nomtype,nomcode,nomamount,nomdate) values ('$COOKIE->{ACCT}',$New_txn_id,'T','$Key','-$Value',$Start_date)");
				$Sts = $dbh->do("insert into nominals (acct_id,link_id,nomtype,nomcode,nomamount,nomdate) values ('$COOKIE->{ACCT}',$New_txn_id,'T','3100','$Value',$Start_date)");

			}
			else {
				$Retained_earnings += $Value;
				$Sts = $dbh->do("insert into nominals (acct_id,link_id,nomtype,nomcode,nomamount,nomdate) values ('$COOKIE->{ACCT}',$New_txn_id,'T','$Key','$Value',$Start_date)");
				$Sts = $dbh->do("insert into nominals (acct_id,link_id,nomtype,nomcode,nomamount,nomdate) values ('$COOKIE->{ACCT}',$New_txn_id,'T','3100','$Value',$Start_date)");
			}

	                $Value =~ tr/-//d;
        	        $Value = sprintf("%1.2f",$Value);

                	$Sts = $dbh->do("insert into audit_trails (acct_id,audtype,audaction,audtext,auduser) values ('$COOKIE->{ACCT}','opening balances','setup','Opening Balance $Adjustment $Acctype{$Key} of &pound;$Value','$COOKIE->{USER}')");
		}
	}

#  Enter the retained earnings value

	$Sts = $dbh->do("update coas set coabalance=coabalance + '$Retained_earnings' where acct_id='$COOKIE->{ACCT}' and coanominalcode='3100'");
        $Retained_earnings = sprintf("%1.2f",$Retained_earnings);

#  See whether we are entering opening balances or making an adjustment  (ie does an opening statement exist?)

	$Stmts = $dbh->prepare("select acc_id,acctype,accshort from statements left join accounts on (acc_id=accounts.id and statements.acct_id=accounts.acct_id) where statements.acct_id='$COOKIE->{ACCT}' and stanotxns='-1'");
	$Stmts->execute;
	if ($Stmts->rows > 0) {

	        $Sts = $dbh->do("insert into audit_trails (acct_id,audtype,audaction,audtext,auduser) values ('$COOKIE->{ACCT}','opening balances','setup','Retained Earnings adjusted by &pound;$Retained_earnings for `Retained Earnings`','$COOKIE->{USER}')");

#  Existing opening balance, so just adjust

		while (@Stmt = $Stmts->fetchrow) {
			$Nomcode = "x".$Stmt[1];
			if ($FORM{$Nomcode}) {
				$Sts = $dbh->do("update statements set staclosebal=staclosebal+'$FORM{$Nomcode}' where acct_id='$COOKIE->{ACCT}' and acc_id=$Stmt[0] and stanotxns='-1'");
#				$Sts = $dbh->do("update statements set staopenbal=staopenbal+'$FORM{$Nomcode}',staclosebal=staclosebal+'$FORM{$Nomcode}' where acct_id='$COOKIE->{ACCT}' and acc_id=$Stmt[0] and stanotxns<>'-1'");
	        		$Sts = $dbh->do("insert into audit_trails (acct_id,audtype,audaction,audtext,auduser) values ('$COOKIE->{ACCT}','opening balances','setup','Adjustment of &pound;$FORM{$Nomcode} for $Stmt[2] Account','$COOKIE->{USER}')");
			}
		}
	}
	else {

	        $Sts = $dbh->do("insert into audit_trails (acct_id,audtype,audaction,audtext,auduser) values ('$COOKIE->{ACCT}','opening balances','setup','Total Retained Earnings of &pound;$Retained_earnings for 3100','$COOKIE->{USER}')");

#  Get the current and deposit account ids

		$Accts = $dbh->prepare("select id,acctype from accounts where acct_id='$COOKIE->{ACCT}' and acctype in ('1200','1210')");
		$Accts->execute;
		$Acct = $Accts->fetchall_hashref('acctype');
		$Accts->finish;

#  create an opening current account statement

		$Sts = $dbh->do("insert into statements (acct_id,acc_id,staclosebal,stastmtno,staclosedate,stanotxns,starec_no) values ('$COOKIE->{ACCT}',$Acct->{1200}->{id},'$FORM{x1200}','$FORM{cstmt}',str_to_date('$FORM{cdate}','%d-%b-%y'),'-1',0)");

#  .. and do the same for the deposit account

		$Sts = $dbh->do("insert into statements (acct_id,acc_id,staclosebal,stastmtno,staclosedate,stanotxns,starec_no) values ('$COOKIE->{ACCT}',$Acct->{1210}->{id},'$FORM{x1210}','$FORM{dstmt}',str_to_date('$FORM{ddate}','%d-%b-%y'),'-1',0)");

#  and finally, update the comacccompleted flag

		$Sts = $dbh->do("update companies set comacccompleted='Y' where reg_id=$Reg_id and id=$Com_id");
	}
	$Stmts->finish;

	print<<EOD;
Content-Type: text/plain

OK-$Reg[0]

EOD
}
$Companies->finish;
$dbh->disconnect;
exit;
