#!/usr/bin/perl

#  script to email a newly added user

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

use DBI;
$dbh = DBI->connect("DBI:mysql:fpa");

($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});

#  get the user name and company name

$Companies = $dbh->prepare("select comname,regusername,comadd_user from companies left join registrations on (companies.reg_id=registrations.reg_id) where companies.id=$Com_id and companies.reg_id=$Reg_id");
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

use Digest;
$Dig =  Digest->new("SHA-1");
$Dig->add($FORM{email}.$COOKIE->{ACCT});
$Activecode = $Dig->hexdigest;

###  Validation

$Errs = "";

unless ($FORM{addemail}) { $Errs .= "<li>No email address</li>\n"; }
if ($FORM{addemail} && $FORM{addemail} !~ /^[\w\-\.\+]+\@[a-zA-Z0-9\.\-]+\.[a-zA-z0-9]{2,4}$/) { $Errs .= "<li>Email address in incorrect format</li>\n"; }
unless ($FORM{addusername}) { $Errs .= "<li>Name not entered</li>\n"; }
if ($FORM{addtype} =~ /New/i) {
	unless ($Company->{comadd_user} > 0) { $Errs .= "<li>You have no further user ids available to assign</li>\n"; }
}
else {

#  Check to see if there is still an unactivated login outstanding

	$Add_users = $dbh->prepare("select * from add_users where addactivecode='$Activecode' and addactive='P'");
	$Add_users->execute;
	unless ($Add_users->rows > 0) { $Errs .= "<li>There is no record of this email address.&nbsp;&nbsp;Either it is incorrect or it has already been activated</li>\n"; }
	$Add_users->finish;
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

	if ($FORM{addtype} =~ /New/i) {
		$Sts = $dbh->do("insert into add_users (addusername,addemail,addactivecode,addreg2_id,addcom_id,adddate,addcomname) values ('$FORM{addusername}','$FORM{addemail}','$Activecode',$Reg_id,$Com_id,now(),'$COOKIE->{TAG}')");
		$Sts = $dbh->do("update companies set comadd_user=comadd_user - 1 where reg_id=$Reg_id and id=$Com_id");
	}

#  Update the cookie file


#  Send the email

	&post_email();
}	
$dbh->disconnect;
exit;

sub post_email {

        $Host = $ENV{SERVER_ADDR};
        if ($Host =~ /^127/) {
                $Host = "www.fpa.co.uk";
        }
        else {
                $Host = "www.freeplusaccounts.co.uk";
        }

	$Addressees = "$FORM{addemail}";
	open(EMAIL,"| /usr/sbin/sendmail -t");
	print EMAIL <<EOD;
From: "FreePlus Registrations" <fparegistrations\@corunna.com>
To: $Addressees
bcc: doug.conran\@corunna.com
Subject: Invitation to access $Company->{comname} Accounts
Content-Type: multipart/alternative;
 boundary="=_NextPart_2rfkindysadvnqw3nerasdf";
        charset="us-ascii"
MIME-Version: 1.0

--=_NextPart_2rfkindysadvnqw3nerasdf
Content-Type: text/plain
Content-Transfer-Encoding: 7bit

===============================================
      FreePlus Accounts Additional User
===============================================

$Company->{regusername} has invited $FORM{addusername} to have login access to $Company->{comname} at FreePlus Accounts accounting system.  If you are this person you will need to activate this login id by going to the following link:-

  http://$Host/cgi-bin/fpa/confirmuser.pl?$Activecode

This code will only be valid for 24 hours from the time of this message and may be safely ignored if you are not the person refered to.

(If you are unable to click on the link above please copy it and then paste it into the Address bar of your browser)

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
<p>$Company->{regusername} has invited $FORM{addusername} to have login access to $Company->{comname} at <b><i>FreePlus Accounts</i></b> accounting system.&nbsp;&nbsp;If you are this person you will need to activate this login id by going to the following link:-</p>
<p><a href="http://$Host/cgi-bin/fpa/confirmuser.pl?$Activecode">http://www.freeplusaccounts.co.uk/cgi-bin/fpa/confirmuser.pl?$Activecode</a></p>
<p>This code will only be valid for 24 hours from the time of this message and may be safely ignored if you are not the person refered to.<br />
(If you are unable to click on the link above please copy it and then paste it into the Address bar of your browser)</p>
<p>Yours Sincerely</p>
<p>FreePlus Accounts</p>
</body>
</html>

--=_NextPart_2rfkindysadvnqw3nerasdf--
EOD
	close(EMAIL);

#  finally, display the welcome screen.  We won't set his uid cookie yet.  Not until he has activated and then logs in

	print "Content-Type: text/html\n\nOK-dashboard.pl\n";
}
