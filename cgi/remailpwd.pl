#!/usr/bin/perl

#  script to email a new password to a user

if ($ENV{QUERY_STRING}) {

#  Set a new password

	$Pwd = "";
	$Pwd2 = "";

	while (length($Pwd) < 8) {
		$Num = int(rand 74) + 48;
		if (($Num>34 && $Num<38) || ($Num>48 && $Num<58) || ($Num>65 && $Num<91) || ($Num>96 && $Num<123)) {
			$Pwd .= chr($Num);
		}
	}

	use DBI;
	$dbh = DBI->connect("DBI:mysql:fpa");

#  Get the registered email address (so that we get the case right)

        $Regs = $dbh->prepare("select regemail from registrations where regemail='$ENV{QUERY_STRING}'");
        $Regs->execute;
        @Reg = $Regs->fetchrow;
        $Regs->finish;

#  Update the registration

	$Sts = $dbh->do("update registrations set regpwd=password('$Pwd') where regemail='$ENV{QUERY_STRING}'");

	$Addressees = "$ENV{QUERY_STRING}";

	if ($Sts > 0) {

		open(EMAIL,"| /usr/sbin/sendmail -t");
		print EMAIL <<EOD;
From: Registrations <fparegistrations\@corunna.com>
To: $Addressees
bcc: doug.conran49\@googlemail.com
Subject: Your New FreePlus Accounts Password

Thank you for using FreePlus Accounts.  A new, temporary, password has been generated for you.

Your new Password is: $Pwd
for your Login ID of: $Reg[0]

Please remember that both your Login ID and your password are case sensitive.

If you continue to have problems logging in please first check that you do not have
CAPS LOCK on.

As a security measure please now log in and change this.

Yours sincerely

The FreePlus Accounts Support Team
EOD
		close(EMAIL);
	}
	else {

		open(EMAIL,"| /usr/sbin/sendmail -t");
		print EMAIL <<EOD;
From: Registrations <fparegistrations\@corunna.com>
To: $Addressees
bcc: doug.conran49\@googlemail.com
Subject: Your Request to FreePlus Accounts

Unfortunately the email address you supplied has not been recognised.

Yours sincerely

The FreePlus Accounts Support Team
EOD
		close(EMAIL);
	}
	$dbh->disconnect;
}
print<<EOD;
Content-Type: text/html
Status: 204 OK

EOD
exit;
