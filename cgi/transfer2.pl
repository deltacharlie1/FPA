#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to process a funds transfer

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

	if ($FORM{dir} =~ /to/i) {
		$FORM{tframt} = 0 - $FORM{tframt};
	}

#  Get the next transaction no

        ($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});
        $Companies = $dbh->prepare("select comnexttxn from companies where reg_id=$Reg_id and id=$Com_id");
        $Companies->execute;
        @Company = $Companies->fetchrow;
        $Companies->finish;
        
        $FORM{txnno} = $Company[0];
        $Sts = $dbh->do("update companies set comnexttxn=comnexttxn+2 where reg_id=$Reg_id and id=$Com_id");

#  Bank Current Account entry

	$Sts = $dbh->do("insert into transactions (acct_id,txnamount,txndate,txnmethod,txntxntype,txncusname,txnremarks,txntxnno,txnyearend) values ('$COOKIE->{ACCT}','$FORM{tframt}',str_to_date('$FORM{tfrdate}','%d-%b-%y'),'1200','transfer','$Tfr{$FORM{acc}}','Funds Transfer','$FORM{txnno}','$COOKIE->{YEAREND}')");
        $New_txn_id = $dbh->last_insert_id(undef, undef, qw(transactions undef));

#  Update the current account nominal code

	$Sts = $dbh->do("update coas set coabalance=coabalance + '$FORM{tframt}' where acct_id='$COOKIE->{ACCT}' and coanominalcode='1200'");
	$Sts = $dbh->do("insert into nominals (acct_id,link_id,nomtype,nomcode,nomamount,nomdate) values ('$COOKIE->{ACCT}',$New_txn_id,'T','1200','$FORM{tframt}',str_to_date('$FORM{tfrdate}','%d-%b-%y'))");

#  Other Account entry

	$Contra_amt = 0 - $FORM{tframt};
	$FORM{txnno}++;

	$Sts = $dbh->do("insert into transactions (acct_id,txnamount,txndate,txnmethod,txntxntype,txncusname,txnremarks,txntxnno,txnyearend) values ('$COOKIE->{ACCT}','$Contra_amt',str_to_date('$FORM{tfrdate}','%d-%b-%y'),'$FORM{acc}','transfer','Current Account','Funds Transfer','$FORM{txnno}','$COOKIE->{YEAREND}')");
        $New_txn_id = $dbh->last_insert_id(undef, undef, qw(transactions undef));

#  Update the other account nominal code

	$Sts = $dbh->do("update coas set coabalance=coabalance - '$FORM{tframt}' where acct_id='$COOKIE->{ACCT}' and coanominalcode='$FORM{acc}'");
	$Sts = $dbh->do("insert into nominals (acct_id,link_id,nomtype,nomcode,nomamount,nomdate) values ('$COOKIE->{ACCT}',$New_txn_id,'T','$FORM{acc}','$Contra_amt',str_to_date('$FORM{tfrdate}','%d-%b-%y'))");

#  Create an audit trail record
        $FORM{tframt} =~ tr/-//d;
        $FORM{tframt} = sprintf("%1.2f",$FORM{tframt});

        $Sts = $dbh->do("insert into audit_trails (acct_id,link_id,audtype,audaction,audtext,auduser) values ('$COOKIE->{ACCT}',$New_txn_id,'transfer.pl','transfer','&pound;$FORM{tframt} transferred $FORM{dir} $Tfr{$FORM{acc}}','$COOKIE->{USER}')");

	print<<EOD;
Content-Type: text/plain

The transaction has been entered
EOD
}
$dbh->disconnect;
exit;
