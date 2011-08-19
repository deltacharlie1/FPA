#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to add a reminder

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

while (( $Key,$Value) = each %FORM) {

#  Remove any bad characters

	$Value =~ tr/\\//d;
	$Value =~ s/\'/\\\'/g;
	$FORM{$Key} = $Value;
}

#  First set some date defaults

if ($FORM{remstartdate}) {
	$Startdate = "str_to_date('$FORM{remstartdate}','%d-%b-%y')";
}
else {
	$Startdate = "curdate()";
}
if ($FORM{remenddate}) {
	$Enddate = "str_to_date('$FORM{remstartdate}','%d-%b-%y')";
}
else {
	$Enddate = "'2049-12-31'";
}

#  Then just save the record

$Sts = $dbh->do("insert into reminders (acct_id,remtext,remcode,remgrade,remstartdate,remenddate) values ('$COOKIE->{ACCT}','$FORM{remtext}','GEN','$FORM{remgrade}',$Startdate,$Enddate)");

print<<EOD;
Content-Type: text/plain

	Your Reminder<p>$FORM{remtext}</p> has been added
EOD
$dbh->disconnect;
exit;
