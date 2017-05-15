#!/usr/bin/perl

use DBI;
$dbh = DBI->connect("DBI:mysql:fpa");
$subs = $dbh->prepare("select reg_id,comsublevel,date_format(comsubdue,'%d-%b-%y') from companies where comsubdue > '2016-04-01'");
$subs->execute();
while (@sub = $subs->fetchrow) {
	$regs = $dbh->prepare("select regemail,regmembership from registrations where reg_id=$sub[0]");
	$regs->execute();
	@reg = $regs->fetchrow;
	if ($reg[1] < 4 && $sub[1] > 0 ) {
		print "$reg[0] - was - $reg[1]\t";
		$dbh->do("update registrations set regmembership='4' where reg_id=$sub[0]");
		$reg1s = $dbh->prepare("select regemail,regmembership from registrations where reg_id=$sub[0]");
		$reg1s->execute();
		@reg = $reg1s->fetchrow;
		print "now - $reg[1] - comsublevel($sub[1]) - comsubdue($sub[2])\n";
	}
	# print "$sub[0]\n";
}
$regs->finish;
$reg1s->finish;
$subs->finish;
$dbh->disconnect;
exit;
