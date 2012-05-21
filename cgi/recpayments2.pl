#!/usr/bin/perl

$ACCESS_LEVEL = 3;

#  Add new recurring payment and return all recurring payments

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

use CGI;

$Data = new CGI;
%FORM = $Data->Vars;

if ($FORM{init} =~ /U/i) {

	$Errs = "";
	unless ($FORM{reccus_id}) { $Errs .= "<li>Empty Supplier Name</li>\n"; }
	unless ($FORM{totamt}) { $Errs .= "<li>Empty Total Amount</li>\n"; }
	unless ($FORM{recdesc}) { $Errs .= "<li>Empty Description</li>\n"; }
	unless ($FORM{recvatrate}) { $Errs .= "<li>Empty VAT Rate</li>\n"; }
	unless ($FORM{recnextdate}) { $Errs .= "<li>Empty Next Due date</li>\n"; }
	unless ($FORM{recfreq}) { $Errs .= "<li>Empty Frequency</li>\n"; }
	unless ($FORM{rectxnmethod}) { $Errs .= "<li>Empty Paid From</li>\n"; }
	unless ($FORM{reccoa}) { $Errs .= "<li>Empty Payment Type</li>\n"; }

	if ($Errs) {
		print<<EOD;
Content-Type: text/plain

You have the following errors:-<ol>
$Errs
</ol>
EOD
		exit;
	}
}
use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");

($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});

if ($FORM{init} =~ /D/i) {
	$Sts = $dbh->do("delete from recpayments where acct_id='$COOKIE->{ACCT}' and id=$FORM{reccus_id}");
}
elsif ($FORM{init} =~ /U/i) {

	$Sts = $dbh->do("insert into recpayments (acct_id,reccus_id,recnextdate,recfreq,rectype,rectxnmethod,reccoa,recdesc,recref,recamount,recvatrate) values ('$COOKIE->{ACCT}',$FORM{reccus_id},str_to_date('$FORM{recnextdate}','%d-%b-%y'),'$FORM{recfreq}','$FORM{rectype}','$FORM{rectxnmethod}','$FORM{reccoa}','$FORM{recdesc}','$FORM{recref}','$FORM{totamt}','$FORM{recvatrate}')");
}

@Freq = ("","Weekly","Fortnightly","Every 28 days","Every 30 days","Monthly","Quarterly","Every 6 months","Annually");

$Recpayments = $dbh->prepare("select recpayments.id as rec_id,cusname,recdesc,recamount,recvatrate,date_format(recnextdate,'%d-%b-%y') as printdate,recfreq,rectxnmethod,reccoa from recpayments left join customers on (reccus_id=customers.id and recpayments.acct_id=customers.acct_id) where recpayments.acct_id='$COOKIE->{ACCT}' order by recnextdate");
$Recpayments->execute;

print "Content-Type: text/plain\n\n";

while ($Recpayment = $Recpayments->fetchrow_hashref) {
	print<<EOD;
<tr>
  <td>$Recpayment->{cusname}</td>
  <td>$Recpayment->{recdesc}</td>
  <td style="text-align:right;">$Recpayment->{recamount}</td>
EOD

	unless ($COOKIE->{VAT} =~ /N/i) {
		print<<EOD;
  <td style="text-align:center;">$Recpayment->{recvatrate}</td>
EOD
	}

	print<<EOD;
  <td>$Recpayment->{printdate}</td>
  <td>$Freq[$Recpayment->{recfreq}]</td>
  <td>$Recpayment->{rectxnmethod}</td>
  <td>$Recpayment->{reccoa}</td>
  <td style="text-align:center;"><img src='/icons/inv_del.png' title='Delete' onclick="dlt('$Recpayment->{rec_id}');"/></td>
</tr>
EOD
}

$dbh->disconnect;
exit;
