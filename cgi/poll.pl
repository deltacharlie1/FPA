#!/usr/bin/perl

# script to capture pool choices

$Vote{'N'} = 'You have voted that you prefer to do your own accounts';
$Vote{'Y'} = 'You have voted that you would prefer to use a bookkeeper';

if ($ENV{QUERY_STRING}) {
	($Email,$Vote,$Poll) = split(/\?/,$ENV{QUERY_STRING});
	use DBI;

	$dbh = DBI->connect("DBI:mysql:fpa");

#  Check that user has not already voted

	$Polls = $dbh->prepare("select id from poll where email='$Email' and poll='$Poll'");
	$Polls->execute;
	
	if ($Polls->rows < 1) {
		$Sts = $dbh->do("insert into poll (email,vote,poll) values ('$Email','$Vote','$Poll')");
	}
	else {
		@Poll = $Polls->fetchrow;
		$Sts = $dbh->do("update poll set vote='$Vote' where id=$Poll[0]");
	}
	$Polls->finish;
	$dbh->disconnect;
}
print<<EOD;
Content-Type: text/html

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<link href="/css/new-css.css" rel="stylesheet" type="text/css" />
<link rel="shortcut icon" href="/favicon.ico"/>
<link rel="stylesheet" href="/css/jquery-ui.css" type="text/css"/>
<script src="/js/jquery.js" type="text/javascript"></script>
<script src="/js/jquery-ui.js" type="text/javascript"></script>
<title>Poll</title>
</head>
<body style='margin:10px 10px;background-image:none;background-color:#ffffff;'>
  <div style="display:inline;float:left;"><img src="/wp-content/themes/freeplusaccounts/images/logo.jpg" alt="Free Plus Accounts" /></div>
  <div style="display:inline;vertical-align:top;"><img style="padding:10px 0 0 20px;vertical-align:top;" src="/wp-content/themes/freeplusaccounts/images/freeplustitle.png" alt="Free Plus Accounts" />
  <div style="margin-top:120px;margin-left:45px;margin-right:0px;width:580px;">
  <table style="padding:10px;" width="520"cellspacing="0" cellpadding="0" border="0" class="formtable">
    <tr>
      <td style="padding:20px;text-align:center;font-size:20px;font-weight:bold;">Thank you for your vote</td>
    </tr>
    <tr>
      <td style="padding:20px;text-align:center;font-size:16px;">$Vote{$Vote}</td>
    </tr>
  </table>
  </div>
</body>
</html>
EOD
exit;
