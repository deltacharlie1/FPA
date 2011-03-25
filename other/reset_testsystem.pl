#!/usr/bin/perl

#  script to reset the test system (only run as a cronbob)

use DBI;
$dbh = DBI->connect("DBI:mysql:fpa");

$COOKIE->{ACCT} = "7+7";

$Sts = $dbh->do("delete from invoices where acct_id='$COOKIE->{ACCT}'");
$Sts = $dbh->do("delete from transactions where acct_id='$COOKIE->{ACCT}'");
$Sts = $dbh->do("delete from inv_txns where acct_id='$COOKIE->{ACCT}'");
$Sts = $dbh->do("delete from audit_trails where acct_id='$COOKIE->{ACCT}'");
$Sts = $dbh->do("delete from statements where acct_id='$COOKIE->{ACCT}'");
$Sts = $dbh->do("delete from vatreturns where acct_id='$COOKIE->{ACCT}'");
$Sts = $dbh->do("delete from vataccruals where acct_id='$COOKIE->{ACCT}'");
$Sts = $dbh->do("delete from reminders where acct_id='$COOKIE->{ACCT}'");
$Sts = $dbh->do("delete from nominals where acct_id='$COOKIE->{ACCT}'");
$Sts = $dbh->do("delete from items where acct_id='$COOKIE->{ACCT}'");
$Sts = $dbh->do("delete from customers where acct_id='$COOKIE->{ACCT}'");

$Sts = $dbh->do("update coas set coabalance='0' where acct_id='$COOKIE->{ACCT}'");
$Sts = $dbh->do("update companies set comname='Test Company',comregno='',comaddress='1 The High Street\nAnytown',compostcode='AB1 1AB',comtel='',comlogo='',combusiness='9',comcontact='',comemail='',comyearend='2011-01-31',comnextsi='100001',comnextpi='500001',comnexttxn='1',comvatscheme='N',comvatno='',comvatcontrol='0',comvatduein='0',comvatqstart='2010-01-01',comvatmsgdue=NULL,comnocheques=0,comrecstats='',compaystats='',comacccompleted='Y',comexpid=0,comoptin='Y',comemailmsg='',comstmtmsg='' where reg_id=7 and id=7");
$dbh->disconnect;
exit;
