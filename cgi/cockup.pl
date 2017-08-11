#!/usr/bin/perl

use DBI;
$dbh = DBI->connect("DBI:mysql:fpa");

$Regs = $dbh->prepare("select regusername,regemail,regactivecode from registrations where regactive='P' and regregdate > '2011-11-12'");
$Regs->execute;
while (@Reg = $Regs->fetchrow) {

	$FORM{name} = $Reg[0];
	$FORM{email} = $Reg[1];
	$Activecode = $Reg[2];

	&post_email;
}
$Regs->finish;
$dbh->disconnect;
exit;

sub post_email {

	$Addressees = "$FORM{email}";
	$Host = "www.freeplusaccounts.co.uk";

	open(EMAIL,"| /usr/sbin/sendmail -t");
	print EMAIL <<EOD;
From: "FreePlus Registrations" <fparegistrations\@corunna.com>
To: $Addressees
bcc: doug.conran49\@googlemail.com
Subject: Your FreePlus Accounts Registration was successful!
Content-Type: multipart/alternative;
 boundary="=_NextPart_2rfkindysadvnqw3nerasdf";
        charset="us-ascii"
MIME-Version: 1.0

--=_NextPart_2rfkindysadvnqw3nerasdf
Content-Type: text/plain
Content-Transfer-Encoding: 7bit

It has come to our attention that a small number of activation emails have been blocked by our mail server.  In case yours was one of those messages we are re-sending it now.  If you have already received your activation email you may safely ignore this message.


================================================
         FreePlus Accounts Registration
================================================


Someone claiming to be $FORM{name} has used this email address to register for a FreePlus Accounts account.  If you are this person you will need to activate your account by going to the following link:-

http://www.freeplusaccounts.co.uk/cgi-bin/fpa/activate.pl?$Activecode

This code will only be valid for 24 hours from the time of registration and may be safely ignored if you are not the person registering.

(If you are unable to click on the link above please copy it and then paste it into the Address bar of your browser.)

May we take this opportunity of thanking you for your interest in the FreePlus Accounts service and we hope that you will find it useful.

Yours Sincerely

FreePlus Accounts


--=_NextPart_2rfkindysadvnqw3nerasdf
Content-Type: text/html
Content-Transfer-Encoding: 7bit

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
<title>FreePlus Accounts Registration</title>
</head>
<body>
<p>It has come to our attention that a small number of activation emails have been blocked by our mail server.&nbsp;&nbsp;In case yours was one of those messages we are re-sending it now.&nbsp;&nbsp;If you have already received your activation email you may safely ignore this message.</p>
<br/>
<p>Someone claiming to be $FORM{name} has used this email address to register for a <b><i>FreePlus Accounts</i></b> account.&nbsp;&nbsp;If you are this person you will need to activate your account by going to the following link:-</p>
<p><a href="http://$Host/cgi-bin/fpa/activate.pl?$Activecode">http://www.freeplusaccounts.co.uk/cgi-bin/fpa/activate.pl?$Activecode</a></p>
<p>This code will only be valid for 24 hours from the time of registration and may be safely ignored if you are not the person registering.<br />
(If you are unable to click on the link above please copy it and then paste it into the Address bar of your browser)</p>
<p>May we take this opportunity of thanking you for your interest in the <b><i>FreePlus Accounts</i></b> service and we hope that you will find it useful.</p>
<p>Yours Sincerely</p>
<p>FreePlus Accounts</p>
</body>
</html>

--=_NextPart_2rfkindysadvnqw3nerasdf--
EOD
	close(EMAIL);
}
