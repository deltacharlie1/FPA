#!/usr/bin/perl

#  script to email a user's emorable word

@Cookie = split(/\;/,$ENV{HTTP_COOKIE});
foreach (@Cookie) {
        ($Name,$Value) = split(/\=/,$_);
        $Name =~ s/^ //g;
        $Value =~ tr/\"//d;
        $Cookie{$Name} = $Value;
}

$Cookie = $Cookie{'fpa-uid'};

if ($Cookie) {

	use DBI;
	my $dbh = DBI->connect("DBI:mysql:fpa");

#  Get the current Memorable word

	$Regs = $dbh->prepare("select regmemword from registrations where regemail='$Cookie'");
	$Regs->execute;
	@Reg = $Regs->fetchrow;
	$Regs->finish;

	$Addressees = $Cookie;

	if ($Reg[0]) {

		open(EMAIL,"| /usr/sbin/sendmail -t");
		print EMAIL <<EOD;
From: Registrations <fparegistrations\@corunna.com>
To: $Addressees
bcc: doug.conran\@corunna.com
Subject: Your FreePlus Accounts Memorable Word

Thank you for using FreePlus Accounts.

Your Memorable Word is: $Reg[0]

As a security measure we suggest that you now log in and change this.

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
bcc: doug.conran\@corunna.com
Subject: Your Request to FreePlus Accounts

Unfortunately we are unable to find your account.

Yours sincerely

The FreePlus Accounts Support Team
EOD
		close(EMAIL);
	}
	$dbh->disconnect;
}
print<<EOD;
Content-Type: text/html
Status: 205 OK

EOD
exit;
