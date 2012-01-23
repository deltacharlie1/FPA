#!/usr/bin/perl

#  Script to run through all subscriotions (comsubdue) due within the next 2 days.  Processing is as follows:-

#  Get last subscription invoice no from subscriptions, if no subscriptions then set it to 5134 :-)
#  For each company record with datediff(comsubdue,now()) < 3

#    send xml
#    Get previouse subscription record
#    If no record or datediff(now(),subdatepaid) > 20 (ie it was more than 20 days ago ergo it is not for this month)
#      If good xml response
#        add paid subscription record
#        send paid invoice email
#      else
#        add due subscription record
#        send first warning email with invoice
#      end
#    else  -  previous non-paid record exists
#      if good xml response
#        update subscription record to paid
#        send email notifying use that sub has been paid
#      else
#        if datediff(comsubdue,now()) < -5  (ie he is 3 days late)
#          update subscription to cancelled
#          revert company & regisrtation records to free system and set comsubdue to 2010-01-01
#          send email to user
#        else
#          send warning message to use
#        end
#      end
#    end
#  end


#  response comes in as xml

use LWP::UserAgent;
use Digest;
use MIME::Base64;

require "/usr/local/git/fpa/cgi/pdf_sub_invoice.ph";

$Termid = '2645001';
$Secret = 'CorunnaSecret';

$Subrate[1] = '5.00';
$Subrate[2] = '5.00';
$Subrate[3] = '10.00';
$Subrate[5] = '10.00';
$Subrate[6] = '20.00';

$Subscription[1] = 'FreePlus Bookkeeper Basic @ '.chr(163).'5.00pm';
$Subscription[2] = 'FreePlus Standard @ '.chr(163).'5.00pm';
$Subscription[3] = 'FreePlus Bookkeeper Standard @ '.chr(163).'10.00pm';
$Subscription[5] = 'FreePlus Premium @ '.chr(163).'10.00pm';
$Subscription[6] = 'FreePlus Bookkeeper Premium @ '.chr(163).'20.00pm';

$Inv_type = 'INVOICE';

$Dte = `date +%d-%m-%Y:%H:%M:%S:000`;
chomp($Dte);

use DBI;
my $dbh = DBI->connect("DBI:mysql:fpa");

#  Get the laast subscription invoice

$Thisdate = "23rd January 2012";

$Subs = $dbh->prepare("select subinvoiceno,date_format(now(),'%D %M %Y') as invdate from subscriptions order by subinvoiceno desc limit 1");
$Subs->execute;
$Sub = $Subs->fetchrow_hashref;
$Inv_date = $Sub->{invdate} || $Thisdate;

$Orderid = $Sub->{subinvoiceno} || 5136;

#  Prepare the subs sql call for use in the loop

$Subs = $dbh->prepare("select id,datediff(now(),subdatepaid) as difsubpaid,substatus from subscriptions where acct_id=? order by subinvoiceno desc limit 1");

#  Get all due subscriptions

$Subscribers = $dbh->prepare("select id,reg_id,comsublevel,commerchantref,comsubref,datediff(comsubdue,now()) as difsubdue,comname,comaddress,compostcode,regemail from companies left join registrations using (reg_id) where comsublevel>0 and comsubdue<>'2010-01-01' and datediff(comsubdue,now()) < 3");	#  ie subscription due within 2 days
$Subscribers->execute;
while ($Subscriber = $Subscribers->fetchrow_hashref) {

	$Orderid++;		#  Increment the order id to the next invoice no
	my $XML_Result = "";

	my $Vat = sprintf('%1.2f',$Subrate[$Subscriber->{comsublevel}] * 0.2);
	my $Total = $Subrate[$Subscriber->{comsublevel}] + $Vat;

#  Try and take the subscription

	my $Hash = Digest->new("MD5");
	$Hash->add($Termid.$Orderid.$Subscriber->{comsubref}.$Total.$Dte.$Secret);
	my $Hash_text = $Hash->hexdigest;

#  Construct the xml to be posted

	my $Content = sprintf<<EOD;
<?xml version="1.0" encoding="UTF-8"?>
<SUBSCRIPTIONPAYMENT>
  <ORDERID>$Orderid</ORDERID>
  <TERMINALID>$Termid</TERMINALID>
  <AMOUNT>$Total</AMOUNT>
  <SUBSCRIPTIONREF>$Subscriber->{comsubref}</SUBSCRIPTIONREF>
  <DATETIME>$Dte</DATETIME>
  <HASH>$Hash_text</HASH>
</SUBSCRIPTIONPAYMENT>
EOD

	my $ua = LWP::UserAgent->new;
	$ua->agent("FPA/0.1");

	my $req = HTTP::Request->new(POST => "https://testcashflows.worldnettps.com/merchant/xmlpayment");
	$req->content_type('text/xml');
	$req->content($Content);

	my $res = $ua->request($req);

#	if ($res->is_success) {


#		my $Res_content = $res->content;

#		my $Res_content = '<ERROR><ERRORSTRING>Multiple payments for one period is not allowed</ERRORSTRING></ERROR>';
#		my $Res_content = '<SUBSCRIPTIONPAYMENTRESPONSE><RESPONSECODE>A</RESPONSECODE><RESPONSETEXT>Authorised</RESPONSETEXT><APPROVALCODE>394381</APPROVALCODE><DATETIME>2012-01-23T14:03:14</DATETIME><HASH>1fef6c5a8cb20398abc7e9892bd6c4d4</HASH></SUBSCRIPTIONPAYMENTRESPONSE>';
		my $Res_content = '<SUBSCRIPTIONPAYMENTRESPONSE><RESPONSECODE>D</RESPONSECODE><RESPONSETEXT>Declined</RESPONSETEXT><APPROVALCODE>394381</APPROVALCODE><DATETIME>2012-01-23T14:03:14</DATETIME><HASH>1fef6c5a8cb20398abc7e9892bd6c4d4</HASH></SUBSCRIPTIONPAYMENTRESPONSE>';

		($XML_Result,$XML_Text,$XML_Auth) = ($Res_content =~ /^.*?CODE>(\w+)<\/RESPONSE.*?TEXT>(\w+)<\/RESPONSETEXT.*?CODE>(.*)?<\/APP.*$/);

#	}

	if ($Res_content =~ /ERROR/i) {

		print $Res_content."\n";

	}
	else {

#  Now process on the xml result

		$Subs->execute("$Subscriber->{reg_id}+$Subscriber->{id}");
		if ($Subs->rows < 1) {
			$Sub->{difsubpaid} = 100;		#  spoof long time ago subscrition
		}
		else {
			$Sub = $Subs->fetchrow_hashref;
		}

#  Does he need to pay next sub?

		if ($Sub->{difsubpaid} > 20 || $Sub->{substatus} =~ /Paid/i) {
			if ($XML_Result =~ /A/i) {
				$Sts = $dbh->do("insert into subscriptions (acct_id,subdatepaid,subinvoiceno,subdescription,subnet,subvat,subauthcode,substatus,submerchantref) values ('$Subscriber->{reg_id}+$Subscriber->{id}',now(),'$Orderid','$Subscription[$Subscriber->{comsublevel}]','$Subrate[$Subscriber->{comsublevel}]','$Vat','$XML_Auth','Paid','$Subscriber->{commerchantref}')");

#  Update to comsubdue value

				$Sts = $dbh->do("update companies set comsubdue=date_add(comsubdue,interval 1 month) where reg_id=$Subscriber->{reg_id} and id=$Subscriber->{id}");

########################################  Send paid invoice email  ############################################
				$Email_msg = sprintf<<EOD;
Your FreePlus Accounts subscription invoice is attached. We have debited your card for the amount due.

You can also access this invoice (and all your previous invoices) by logging in to your account and going to Admin -> My Account.

Thank you for your continued custom, it's very much appreciated.

The FreePlus Accounts Support.
EOD
				$Inv_invoice_no = $Orderid;
				$Inv_authcode = $XML_Auth;
				$Inv_address = $Subscriber->{comname}."\n".$Subscriber->{comaddress}."  ".$Subscriber->{compostcode};
				$Inv_desc = $Subscription[$Subscriber->{comsublevel}];
				$Inv_net = $Subrate[$Subscriber->{comsublevel}];
				$Inv_vat = $Vat;
				$Inv_status = 'Paid';

				&send_email();

			}
			else {
				$Sts = $dbh->do("insert into subscriptions (acct_id,subdatepaid,subinvoiceno,subdescription,subnet,subvat,subauthcode,substatus,submerchantref,subreason) values ('$Subscriber->{reg_id}+$Subscriber->{id}',now(),'$Orderid','$Subscription[$Subscriber->{comsublevel}]','$Subrate[$Subscriber->{comsublevel}]','$Vat','$XML_Auth','Due','$Subscriber->{commerchantref}','$XML_Text')");

#######################################  Send due invoice email  ##########################################
				$Email_msg = sprintf<<EOD;
Your FreePlus Accounts subscription invoice is attached.

We have not been able to debit your card for the amount due as the payment has been declined with the reason '$XML_Text' being given.

For the timebeing your subscription is still valid but if you wish to continue using the additional FreePlus Accounts features would you pleas address this issue by logging in to your account, going to Admin -> My Account and updating your card details.  We will attempt to take payment again in the next day or so.

You can also access this invoice (and all your previous invoices) by logging in to your account and going to Admin -> My Account.

Thank you for your continued custom, it's very much appreciated.

The FreePlus Accounts Support.
EOD
				$Inv_invoice_no = $Orderid;
				$Inv_authcode = $XML_Auth;
				$Inv_address = $Subscriber->{comname}."\n".$Subscriber->{comaddress}."  ".$Subscriber->{compostcode};
				$Inv_desc = $Subscription[$Subscriber->{comsublevel}];
				$Inv_net = $Subrate[$Subscriber->{comsublevel}];
				$Inv_vat = $Vat;
				$Inv_status = 'Due';

				&send_email();

			}
		}
		else {
			if ($XML_Result =~ /A/i) {
				$Sts = $dbh->do("update subscriptions set subdatepaid=now(),substatus='Paid',subauthcode='$XML_Auth',subreason='' where id=$Sub->{id}");
				$Sts = $dbh->do("update companies set comsubdue=date_add(comsubdue,interval 1 month) where reg_id=$Subscriber->{reg_id} and id=$Subscriber->{id}");

######################################  send paid email  #############################################
				$Email_msg = sprintf<<EOD;
Thank you, we have now taken payment for your subscription and have debited your card for the amount due.

You can also access the previously sent invoice (and all earlier invoices) by logging in to your account and going to Admin -> My Account.

Thank you for your continued custom, it's very much appreciated.

The FreePlus Accounts Support.
EOD
				$Inv_status = 'No Invoice';

				&send_email();
			}
			else {

				if ($Subscriber->{difsubdue} < 0 && $Sub->{substatus} !~ /Overdue/i) {
					$Sts = $dbh->do("update subscriptions set substatus='Overdue' where id=$Sub->{id}");
######################################  send overdue email  ##########################################
					$Email_msg = sprintf<<EOD;
Hi, we've still not been able to take payment for your subscription, which is now overdue.

If this is because your card has expired or for some other reason it would be helpful if you could update your card details by logging in to your account, going to Admin -> My Account and updating your card details.

If you think that there is some other problem please contact Customer Support at support\@freeplusaccounts.co.uk and we'll look in to it for you.

If you just wish to cancel your subscription you can easily do that (and save us bothering you again!) by logging  in to your account, going to Admin -> My Account and cancelling your subscription there.

You can also access this invoice (and all your previous invoices) by logging in to your account and going to Admin -> My Account.

The FreePlus Accounts Support.
EOD
					$Inv_status = 'No Invoice';

					&send_email();
				}
				elsif ($Subscriber->{difsubdue} < -3) {
					$Sts = $dbh->do("update subscriptions set substatus='Cancelled' where id=$Sub->{id}");
					$Sts = $dbh->do("update companies set compt_logo='2010-01-01',comsubdue='2010-01-01',comsublevel='00',comsubref='' where reg_id=$Subscriber->{reg_id} and id=$Subscriber->{id}");
					$Sts = $dbh->do("update registrations set regmembership='1' where reg_id=$Subscriber->{reg_id}");
##################################### send cancellation email  #######################################
					$Email_msg = sprintf<<EOD;
After a number of attempts we are still unable to debit your card for the amount due on your subscription.  Regretably, therefore, your subscription is now cancelled and you have been reverted back to the free system.

If you think that there has been some error, please contact FreePlus Accounts Technical support at support\@freeplusaccounts.co.uk and we will look in to it for you.

The FreePlus Accounts Support.
EOD
					$Inv_status = 'No Invoice';

					&send_email();
##################################### do XML delete subscription  ####################################

					$Hash = Digest->new("MD5");
					$Hash->add($Termid.$Subscriber->{comsubref}.$Dte.$Secret);
					$Hash_text = $Hash->hexdigest;

					$Content = sprintf<<EOD;
<?xml version="1.0" encoding="UTF-8"?>
<DELETESUBSCRIPTION>
  <MERCHANTREF>$Subscriber->{comsubref}</MERCHANTREF>
  <TERMINALID>$Termid</TERMINALID>
  <DATETIME>$Dte</DATETIME>
  <HASH>$Hash_text</HASH>
</DELETESUBSCRIPTION>
EOD

					my $ua = LWP::UserAgent->new;
					$ua->agent("FPA/0.1");

					my $req = HTTP::Request->new(POST => "https://testcashflows.worldnettps.com/merchant/xmlpayment");
					$req->content_type('text/xml');
					$req->content($Content);

					my $res = $ua->request($req);

					$Res_content = $res->content;

print "Delete - $Res_content\n";


				}
				else {
					$Email_msg = sprintf<<EOD;
This is just a quick message to let you know that we are still having a problem taking payment for your subscription, please contact Customer Support at support\@freeplusaccounts.co.uk to help resolve this issue.

The FreePlus Accounts Support.
EOD
					$Inv_status = 'No Invoice';

					&send_email();
					print "Overdue but not cancelled\n";
				}
			}
		}
	}
}
$Subscribers->finish;
$Subs->finish;
$dbh->disconnect;
exit;

sub send_email {
	($PDF_data) = &pdf_invoice();

        $Encoded_msg = encode_base64($PDF_data);

        open(EMAIL,"| /usr/sbin/sendmail -t");
        print EMAIL<<EOD;
From: FreePlus Accounts <fpainvoices\@corunna.com>
To: doug.conran\@corunna.com
Reply-To: Doug Conran <doug.conran\@corunna.com>
Subject: Your FreePlus Subscription
MIME-Version: 1.0
Content-Type: multipart/mixed;
        boundary="----=_NextPart_000_001D_01C0B074.94357480"
Message-Id: <$Subscriber->{commerchantref}>
From: FreePlus Accounts <fpainvoices\@corunna.com> 
X-Priority: 3
X-Mailer: Postfix v2.0
X-MimeOLE: Produced By Microsoft MimeOLE V5.50.4133.2400
X-MSMail-Priority: Normal

This is a multi-part message in MIME format.
 
------=_NextPart_000_001D_01C0B074.94357480
Content-Type: text/plain;
        charset="iso-8859-1"

$Email_msg

EOD

	unless ($Inv_status =~ /No Invoice/i) {

		print EMAIL<<EOD;
------=_NextPart_000_001D_01C0B074.94357480
Content-Type: application/pdf;
        name="$Inv_invoice_no.pdf"
Content-Transfer-Encoding: base64
Content-Disposition: attachment;
        filename="$Inv_invoice_no.pdf"

$Encoded_msg 

EOD
	}
	print EMAIL<<EOD;
------=_NextPart_000_001D_01C0B074.94357480--

EOD
        close(EMAIL);
}

