#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to delete attachments

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

use CGI;
use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");
($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});

$Data = CGI->new();
$Id = $Data->param('id');

#  First get the filename and directory of the file to be delete

$Images = $dbh->prepare("select imgfilename from images where acct_id='$COOKIE->{ACCT}' and id=$Id");
$Images->execute;
$Image = $Images->fetchrow_hashref;
$Images->finish;

($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});
$Companies = $dbh->prepare("select comdocsdir from companies where reg_id=$Reg_id and id=$Com_id");
$Companies->execute;
$Company = $Companies->fetchrow_hashref;
$Companies->finish;

unlink("$Company->{comdocsdir}/$Image->{imgfilename}");

#  Finally delete the reference to it

$Sts = $dbh->do("delete from images where id=$Id and acct_id='$COOKIE->{ACCT}'");
$dbh->disconnect;
print<<EOD;
Content-Type: text/plain
Status: 200 OK

EOD
exit;
