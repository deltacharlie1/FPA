#!/usr/bin/perl

#  script to email a newly added user

$ACCESS_LEVEL = '3';

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");

($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});

#  get the user name and company name

$Companies = $dbh->prepare("select regcompanyname,regusername from registrations where reg_id=$Reg_id");
$Companies->execute;
$Company = $Companies->fetchrow_hashref;
$Companies->finish;

read(STDIN, $Buffer, $ENV{'CONTENT_LENGTH'});

@pairs = split(/&/,$Buffer);

foreach $pair (@pairs) {

        ($Name, $Value) = split(/=/, $pair);

        $Value =~ tr/+/ /;
        $Value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C",hex($1))/eg;
        $Value =~ tr/\\//d;             #  Remove all back slashes
        $Value =~ s/(\'|\")/\\$1/g;
        $FORM{$Name} = $Value;
}

###  Validation

$Errs = "";

unless ($FORM{email}) { $Errs .= "<li>No email address</li>\n"; }
if ($FORM{email} && $FORM{email} !~ /^[\w\-\.\+]+\@[a-zA-Z0-9\.\-]+\.[a-zA-z0-9]{2,4}$/) { $Errs .= "<li>Email address in incorrect format</li>\n"; }

#  Find the com id of company being invited

$Invitees = $dbh->prepare("select reg_id,id from companies left join registrations using (reg_id) where regemail='$FORM{email}'");
$Invitees->execute;
if ($Invitees->rows > 0) {
	$Invitee = $Invitees->fetchrow_hashref;
}
else {
	$Errs .= "<li>There is no user registered for email address $FORM{email}</li>\n";
}
$Invitees->finish;

unless ($Errs) {
	use Digest;
	$Dig =  Digest->new("MD5");
	$Dig->add($FORM{email}.$COOKIE->{ACCT});
	$Activecode = $Dig->hexdigest;

#  CXheck to see if this activation code is already in use

	$Addusers = $dbh->prepare("select * from add_users where addactivecode='$Activecode'");
	$Addusers->execute;
	if ($Addusers->rows > 0) {
		$Errs .= "<li>A response is already being awaited from this email addressee</li>\n";
	}
	$Addusers->finish;
}

if ($Errs) {
	print<<EOD;
Content-Type: text/html

You have the following error(s):-
<ol>$Errs</ol>
Please return to the previous screen to correct them and then re-submit.
EOD
}
else {

#  looks OK

#  addreg2_id = reg id of bookkeeper		$Reg_id
#  addcom_id = id of new client's company id	$Invitee->{id}

	$Sts = $dbh->do("insert into add_users (addusername,addemail,addactivecode,addreg2_id,addcom_id,adddate,addcomname) values ('$Company->{regcompanyname}','$FORM{email}','$Activecode',$Reg_id,$Invitee->{id},now(),'$COOKIE->{TAG}')");

#  Add a reminder to the invitee

	$Sts = $dbh->do("insert into reminders (acct_id,remtext,remcode,remstartdate,remenddate) values ('$Invitee->{reg_id}+$Invitee->{id}','<a href=\"#\" onclick=\"window.open(\\\'http://www.freeplusaccounts.co.uk/cgi-bin/fpa/invite_existing_user3.pl?$Activecode\\\',\\\'invite\\\',\\\'top=50,left=200,width=500,height=500\\\');\">$Company->{regcompanyname} has invited you to be a client. Please click here to accept</a>','GENINV',now(),'2099-01-01')");

#  Send the email

	&post_email();

#  finally, display the welcome screen.  We won't set his uid cookie yet.  Not until he has activated and then logs in

	print<<EOD;
Content-Type: text/html

Your invitation has been sent to $FORM{email} and is awaiting his/her acceptance.
EOD
}	
$dbh->disconnect;
exit;

sub post_email {

#	$FORM{email} = "dwc\@localhost";

	open(EMAIL,"| /usr/sbin/sendmail -t");
	print EMAIL <<EOD;
From: "FreePlus Registrations" <fparegistrations\@corunna.com>
To: $FORM{email}
bcc: doug.conran\@corunna.com
Subject: Invitation from $Company->{regcompanyname}
Content-Type: multipart/alternative;
 boundary="=_NextPart_2rfkindysadvnqw3nerasdf";
        charset="us-ascii"
MIME-Version: 1.0

--=_NextPart_2rfkindysadvnqw3nerasdf
Content-Type: text/plain
Content-Transfer-Encoding: 7bit

$Company->{regcompanyname} has invited you to join their accountancy practice.  If you accept this invitation you will need to allow them access by going to the following link:-

  http://www.freeplusaccounts.co.uk/cgi-bin/fpa/invite_existing_user3.pl?$Activecode

This code will only be valid for 72 hours from the time of this message and may be safely ignored if you do not wish to accept this invitation.

(If you are unable to click on the link above please copy it and then paste it into the Address bar of your browser)

When you next log in to your account, if you have not already activated this invitation, you will find an invitation reminder with a link that you may also click on.

Yours Sincerely

FreePlus Accounts


--=_NextPart_2rfkindysadvnqw3nerasdf
Content-Type: text/html
Content-Transfer-Encoding: 7bit

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
<title>FreePlus Accounts Additional User</title>
</head>
<body>
<p>$Company->{regcompanyname} has invited you to join their accountancy practice.  If you accept this invitation you will need to activate this login id by going to the following link:-</p>
<p><a href="http://www.freeplusaccounts.co.uk/cgi-bin/fpa/invite_existing_user3.pl?$Activecode">http://www.freeplusaccounts.co.uk/cgi-bin/fpa/invite_existing_user3.pl?$Activecode</a></p>
<p>This code will only be valid for 72 hours from the time of this message and may be safely ignored if you do not wish to accept this invitation.<br />
(If you are unable to click on the link above please copy it and then paste it into the Address bar of your browser)</p>
<p>When you next log in to your account, if you have not already activated this invitation, you will find an invitation reminder with a link that you may also click on.</p>
<p>Yours Sincerely</p>
<p>FreePlus Accounts</p>
</body>
</html>

--=_NextPart_2rfkindysadvnqw3nerasdf--
EOD
	close(EMAIL);
}
