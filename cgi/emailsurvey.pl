#!/usr/bin/perl

#  Script to bul email users with the survey


use DBI;
$dbh = DBI->connect("DBI:mysql:fpa");

#  Get the registered email address (so that we get the case right)

 $Regs = $dbh->prepare("select regemail,regusername,reg_id from registrations where reglastemail < 1 and date_add(regregdate, interval 14 day) < now()");
$Regs->execute;
while (@Reg = $Regs->fetchrow) {

	$Sts = $dbh->do("update registrations set reglastemail=reglastemail+1 where reg_id=$Reg[2]");

	open(EMAIL,"| /usr/sbin/sendmail -t");
#	open(EMAIL,">>/tmp/email.txt");
	print EMAIL <<EOD;
From: FreePlus Accounts <survey\@freeplusaccounts.co.uk>
To: $Reg[0]
Subject: FreePlus Accounts - Customer Satisfaction Survey

Dear $Reg[1]

Thank you for registering with FreePlus Accounts, we hope that you are finding it a useful service.

From feedback that we receive, and from our own experience, we get many suggestions on how to make our system even better and so are constantly making small improvements.  All of these changes get announced in our newsletters, along with tips on how to get the best out of the system and special offers that our sponsors make so please make sure to read them so as to get the maximum benefit from the site.

We are always keen to hear from you, particularly if you have any suggestions to make or would like to give us a testimonial that we can use.  You can do this very easily by just replying to this email or by logging in and leaving Feedback (Admin -> Add Feedback).


Thank you once again,

Best wishes and happy accounting

Yours sincerely

The FreePlus Accounts Support Team
EOD
	close(EMAIL);
}
$Regs->finish;
$dbh->disconnect;
exit;
