#!/usr/bin/perl

$Buffer = $ENV{QUERY_STRING};

@pairs = split(/&/,$Buffer);

foreach $pair (@pairs) {

        ($Name, $Value) = split(/=/, $pair);

        $Value =~ tr/+/ /;
        $Value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C",hex($1))/eg;
        $Value =~ tr/\\\'//d;
        $FORM{$Name} = $Value;
}

if ($FORM{first} !~ /Geoff/ || $FORM{last} !~ /Sissons/) {
exit;
}

print<<EOD;
<html>
<body>
<h2>For: $FORM{first} $FORM{last}</h2>
<table border=1>
<tr>
<td align="center">Name</td>
<td align="center">Amount Due</td>
<td>No Invoices</td>
<td>Earliest</td>
<td align="center">FPA due</td>
<td align="center">Different?</td>
</tr>
EOD

use DBI;
$dbh = DBI->connect("DBI:mysql:fpa");
$Invoices = $dbh->prepare("select (invtotal+invvat - invpaid - invpaidvat) as tot,invtotal,invpaid,invstatus,invstatuscode,date_format(invduedate,'%d-%b-%y') as due,invduedate from invoices where acct_id=? and cus_id=? and invstatuscode > 2 order by invduedate desc"); 
$Customers = $dbh->prepare("select id,cusname,cusaddress,cuspostcode,cusregion,custel,cuscontact,cusbalance,cuscredit,cuslimit,cusdefpaymethod,cussuppress from customers where acct_id=? and cussales='Y' order by cusname");
$Customers->execute("1223+1225");
while ($Customer = $Customers->fetchrow_hashref) {
	$Invoices->execute("1223+1225",$Customer->{id});
	$Tot_owed = 0;
	$Tot_cnt = 0;
	$Tot_date = "";
	while ($Invoice = $Invoices->fetchrow_hashref) {
		if ($Invoice->{tot} != 0) {
			$Tot_owed += $Invoice->{tot};
			$Tot_cnt++;
			$Tot_date = $Invoice->{due};
		}
	}
	if ($Tot_owed != 0) {
		$Sts = $dbh->do("update customers set cusbalance = '$Tot_owed' where acct_id='1223+1225' and id=$Customer->{id}");
		$Diff = "&nbsp;";
		if ($Tot_owed != $Customer->{cusbalance}) {
			$Diff = "Y";
		}
		printf( "<tr><td>$Customer->{cusname}</td><td>%.2f</td><td>$Tot_cnt</td><td>$Tot_date</td><td>$Customer->{cusbalance}</td><td align='center'>$Diff</td></tr>\n",$Tot_owed);
	}
	else {
		$Sts = $dbh->do("update customers set cusbalance = '0.00' where acct_id='1223+1225' and id=$Customer->{id}");
	}
}
print<<EOD;
</table>
</body>
</html>
EOD
$Invoices->finish;
$Customers->finish;
$dbh->disconnect;
exit;

