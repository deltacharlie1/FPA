#!/usr/bin/perl

#  Script to send a bookkeeper invite to an existing user.  Message is a reminder with a link to do the switch

#  First let's see if this activation code matches what we have in add_users

use DBI;
$dbh = DBI->connect("DBI:mysql:fpa");

$Add_users = $dbh->prepare("select * from add_users where addactive='P' and addactivecode=? limit 1");
$Add_users->execute("$ENV{QUERY_STRING}");
$Add_user = $Add_users->fetchrow_hashref;

#  Show error message if this does not exist

unless ($Add_users->rows > 0) {
#  Show error message

	print<<EOD;
Content-Type: text/html

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en" xml:lang="en">
<head>
<title>Activation - Error</title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<link rel="stylesheet" type="text/css" href="http://www.freeplusaccounts.co.uk/wp-content/themes/freeplusaccounts/style.css"/>
<script src="http://www.freeplusaccounts.co.uk/wp-content/themes/freeplusaccounts/js/cufon/cufon.js" type="text/javascript"></script>
<script src="http://www.freeplusaccounts.co.uk/wp-content/themes/freeplusaccounts/js/cufon/font.js" type="text/javascript"></script>
<script src="http://www.freeplusaccounts.co.uk/wp-content/themes/freeplusaccounts/js/cufon/settings.js" type="text/javascript"></script>
</head>
<body>
<h1>Activation Error</h1>
This activation code no longer exists.&nbsp;&nbsp;Please contact $Add_user->{addcomname} if you would still like to use their services.
</body>
</html>
EOD
}
else {

#  Get the existing acct_id of this invitee

	$Invitees = $dbh->prepare("select reg_id from companies where id='$Add_user->{addcom_id}'");
	$Invitees->execute;
	$Invitee = $Invitees->fetchrow_hashref;
	$Invitees->finish;

	$Old_acct_id = "$Invitee->{reg_id}+$Add_user->{addcom_id}";
	$New_acct_id = "$Add_user->{addreg2_id}+$Add_user->{addcom_id}";

	$Sts = $dbh->do("delete from reminders where acct_id='$Old_acct_id' and remcode='GENINV'");
 
#  update all tables with the bookkeeper's reg_id

	$Sts = $dbh->do("update reg_coms set reg2_id=$Add_user->{addreg2_id} where reg1_id=$Invitee->{reg_id} and com_id=$Add_user->{addcom_id}");
	$Sts = $dbh->do("update companies set reg_id=$Add_user->{addreg2_id} where reg_id=$Invitee->{reg_id} and id=$Add_user->{addcom_id}");
	$Sts = $dbh->do("update accounts set acct_id='$New_acct_id' where acct_id='$Old_acct_id'");
	$Sts = $dbh->do("update coas set acct_id='$New_acct_id' where acct_id='$Old_acct_id'");
	$Sts = $dbh->do("update nominals set acct_id='$New_acct_id' where acct_id='$Old_acct_id'");
	$Sts = $dbh->do("update customers set acct_id='$New_acct_id' where acct_id='$Old_acct_id'");
	$Sts = $dbh->do("update invoices set acct_id='$New_acct_id' where acct_id='$Old_acct_id'");
	$Sts = $dbh->do("update items set acct_id='$New_acct_id' where acct_id='$Old_acct_id'");
	$Sts = $dbh->do("update transactions set acct_id='$New_acct_id' where acct_id='$Old_acct_id'");
	$Sts = $dbh->do("update inv_txns set acct_id='$New_acct_id' where acct_id='$Old_acct_id'");
	$Sts = $dbh->do("update vatreturns set acct_id='$New_acct_id' where acct_id='$Old_acct_id'");
	$Sts = $dbh->do("update vataccruals set acct_id='$New_acct_id' where acct_id='$Old_acct_id'");
	$Sts = $dbh->do("update statements set acct_id='$New_acct_id' where acct_id='$Old_acct_id'");
	$Sts = $dbh->do("update audit_trails set acct_id='$New_acct_id',audstamp=audstamp where acct_id='$Old_acct_id'");
	$Sts = $dbh->do("update reminders set acct_id='$New_acct_id' where acct_id='$Old_acct_id'");
	$Sts = $dbh->do("update tempstacks set acct_id='$New_acct_id' where acct_id='$Old_acct_id'");
	$Sts = $dbh->do("update images set acct_id='$New_acct_id' where acct_id='$Old_acct_id'");
	$Sts = $dbh->do("update subscriptions set acct_id='$New_acct_id' where acct_id='$Old_acct_id'");
	$Sts = $dbh->do("update invoice_layouts set acct_id='$New_acct_id' where acct_id='$Old_acct_id'");
	$Sts = $dbh->do("update invoice_layout_items set acct_id='$New_acct_id' where acct_id='$Old_acct_id'");
	$Sts = $dbh->do("update journals set acct_id='$New_acct_id' where acct_id='$Old_acct_id'");
	$Sts = $dbh->do("update recpayments set acct_id='$New_acct_id' where acct_id='$Old_acct_id'");

	@Cookie = split(/\;/,$ENV{HTTP_COOKIE});
	foreach (@Cookie) {
        	($Name,$Value) = split(/\=/,$_);
	        $Name =~ s/^ //g;
        	$Value =~ tr/\"//d;
	        $Cookie{$Name} = $Value;
	}

	open(FILE,"</projects/tmp/$Cookie{'fpa-cookie'}");
	while (<FILE>) {
        	chomp($_);
	        ($Key,$Value) = split(/\t/,$_);
        	$DATA{$Key} = $Value;
	}
	close(FILE);

	$DATA{ACCT} = "$New_acct_id";
	$DATA{BACCT} = "$New_acct_id";

	unlink("</projects/tmp/$Cookie{'fpa-cookie'}");
	open(FILE,">/projects/tmp/$Cookie{'fpa-cookie'}");
	while (($Key,$Value) = each %DATA) {
		print FILE "$Key\t$Value\n";
	}
	close(FILE);

	print<<EOD;
Content-Type: text/html

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en" xml:lang="en">
<head>
<title>iActivation - Success</title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<link rel="stylesheet" type="text/css" href="http://www.freeplusaccounts.co.uk/wp-content/themes/freeplusaccounts/style.css"/>
<script src="http://www.freeplusaccounts.co.uk/wp-content/themes/freeplusaccounts/js/cufon/cufon.js" type="text/javascript"></script>
<script src="http://www.freeplusaccounts.co.uk/wp-content/themes/freeplusaccounts/js/cufon/font.js" type="text/javascript"></script>
<script src="http://www.freeplusaccounts.co.uk/wp-content/themes/freeplusaccounts/js/cufon/settings.js" type="text/javascript"></script>
</head>
<body>
<h1>Activation Success</h1>
Thank you, your account may now be managed by $Add_user->{addusername}.
</body>
</html>
EOD
}
$dbh->disconnect;
exit;
