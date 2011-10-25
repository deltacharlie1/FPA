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

Now that you have had a bit of time to try it out we would be very interested to get your views on how easy you find it and how well it meets your needs.  We would be grateful if you would just reply to this email, responding to each of the questions below by giving a score between 1 and 10 (1 being low and 10 being high) and adding any comments you may wish to make.

We guarantee to you that none of the information you give us will be passed on to any advertisers or third parties.  It will be used solely to help us enhance and improve what we hope is already a very good application.


1.  How easy did you find it to discover our website?

Your score for Q1  -  


2.  What was it that influenced you to try out FreePlus Accounts (please just put 'YES' against each point that applies)?

    -  that it is free?
    -  that it is easy to use and meets your needs?
    -  that it seems to offer a better alternative to your current accounting arrangement?


3.  How easy was the registration process, including the speed with which you received your activation email?

Your score for Q3  -  


4.  How satisfied are you with the login procedure?  Would you prefer to do without the memorable word part?

Your score for Q4  -  


5.  How easy did you find it to enter the initial company details and do you feel that any other information should be required?

Your score for Q5  -  


6.  How well does the quotations/sales invoicing process meet your requirements?

Your score for Q6  -  


7.  How well does the purchase invoicing process meet your requirements?

Your scors for Q7  -  


8.  How easy do you find the bank reconciliation process?

Your score for Q8  -  


9.  If you have registered for VAT, how easy do you find the VAT return process?

Your score for Q9  -  


10.  How well do the reports and 'Front Page' give you a quick idea of the state of your business?  Are there any improvements you would like to see?

Your score for Q10  -  


11.  Overall, how good do you think FreePlus Accounts is for meeting your accounting needs?

Your score for Q11  -  


It would also be helpful to us if you would tell us what type of business you are (sole trader, limited company, VAT registered etc) and whether you have any employees.

Thank you for the time you have taken to respond to this survey, your help now will help us to help others like you.

Finally, if you like FreePlus Accounts, would you like to write a short testimonial in the section below that we can use on our website?

---------  Testimonial  ----------

----------------------------------

Thank you, once again,

Yours sincerely

The FreePlus Accounts Support Team
EOD
	close(EMAIL);
}
$Regs->finish;
$dbh->disconnect;
exit;
