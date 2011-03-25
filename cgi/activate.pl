#!/usr/bin/perl

#  script to confirm registration of a new client

use Template;

use DBI;
my $dbh = DBI->connect("DBI:mysql:fpa");

#  First let's see if this activation code matches what we have in registrations

$Regs = $dbh->prepare("select reg_id,regusername,regemail,to_days(now())-to_days(regregdate),date_format(date_add(now(), interval 6 month),'%a, %d %b %Y %k:%i:%s GMT') from registrations where regactivecode='$ENV{QUERY_STRING}'");
$Regs->execute;
@Reg = $Regs->fetchrow;
$Regs->finish;
	
$tt = Template->new({
	INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
	WRAPPER => 'wrapper.tt',
});

if ($Regs->rows > 0) {

#  This is an okay activation (for the time being activate no matter how tardy)

#  Set the regactive flag to C, the last login date and the uid cookie

$Sts = $dbh->do("update registrations set reglastlogindate=now(),regactive='C',regactivecode='' where reg_id=$Reg[0]");

#  ... and then display the ready to login screen


	$Vars = {
		title => 'Activation Error',
	};

	print<<EOD;
Content-Type: text/html
Set-Cookie: fpa-uid=$Reg[2]; path=/; expires=$Reg[4];

EOD
	$tt->process('activated.tt',$Vars);
}
else {

#  This is not valid, either it is an incorrect activation code or the account has been deleted	

	$Vars = {
		title => 'Activation Error',
	};
	print "Content-Type: text/html\n\n";

	$tt->process('notactivated.tt',$Vars);
}
$dbh->disconnect;
exit;
