#!/usr/bin/perl

#  Script to update companies.customers and invoices with a default message

$Emailmsg = sprintf<<EOD;
Please find our invoice no <invoice#> attached.

Best Regards

Doug Conran
Corunna Systems Ltd
EOD

$Stmtmsg = sprintf<<EOD;
Please find attached our statement for the month of <month#>.

Best Regards

Doug Conran
Corunna Systems Ltd
EOD

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");
$Sts = $dbh->do("update companies set comemailmsg='$Emailmsg',comstmtmsg='$Stmtmsg' where id=1");
$Sts = $dbh->do("update customers set cusemailmsg='$Emailmsg',cusstmtmsg='$Stmtmsg' where acct_id='1+1'");
$dbh->disconnect;
exit;
