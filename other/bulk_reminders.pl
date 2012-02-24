#!/usr/bin/perl
use DBI;

$dbh = DBI->connect("DBI:mysql:fpa");

$Companies = $dbh->prepare("select distinct reg_id,id from companies");
$Companies->execute;
while ($Company = $Companies->fetchrow_hashref) {
	$Acct_id = $Company->{reg_id}."+".$Company->{id};

	$Sts = $dbh->do("insert into reminders (acct_id,remtext,remcode,remgrade,remstartdate,remenddate) values ('$Acct_id','<span style=\"font-weight:bold;font-size:1.2em;color:#000000;\">IMPORTANT!</span> - Please make sure to read our next newsletter (due on Wednesday, 22nd Feb) as it contains important information regarding changes we are making to FreePlus Accounts.','GEN','H',now(),'2012-03-01')");
}
$Companies->finish;
$dbh->disconnect;
exit;
