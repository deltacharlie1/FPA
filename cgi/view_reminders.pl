#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to view reminders

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");
unless ($COOKIE->{NO_ADS}) {
	require "/usr/local/git/fpa/cgi/display_adverts.ph";
	&display_adverts();
}

$HTML = sprintf<<EOD;
<table border="0" cellpadding="0" cellspacing="0" width="100%" class="listing">
EOD

$BG[0] = "odd";
$BG[1] = "even";

$Ndx = 0;

$Reminders = $dbh->prepare("select remtext,remgrade from reminders where acct_id='$COOKIE->{ACCT}' and remstartdate <= curdate() and remenddate >= curdate()");
$Reminders->execute;
while (@Reminder = $Reminders->fetchrow) {
	$Ndx = ! $Ndx;
	$BG = $BG[$Ndx];
	if ($Reminder[1] =~ /H/i) {
		$Style = ' style="background-color:#f9dfc3;"';
	}
	else {
		$Style = "";
	}

	$HTML .= sprintf<<EOD;
  <tr class="$BG"$Style>
    <td>$Reminder[0]</td>
  </tr>
EOD
}
$HTML .= sprintf<<EOD;
</table>
EOD

print<<EOD;
Content-Type: text/plain

$HTML
EOD
$dbh->disconnect;
exit;
