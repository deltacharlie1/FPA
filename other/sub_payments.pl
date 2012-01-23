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

$Subs = $dbh->prepare("select subinvoiceno,date_format(now(),'%D %M %Y') as invdate from subscriptions order by subinvoiceno desc limit 1");
$Subs->execute;
$Sub = $Subs->fetchrow_hashref;
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

	if ($res->is_success) {

		my $Res_content = $res->content;

warn $Res_content."\n";

		($XML_Result,$XML_Text,$XML_Auth) = ($Res_content =~ /^.*?CODE>(\w+)<\/RESPONSE.*?TEXT>(\w+)<\/RESPONSETEXT.*?CODE>(.*)?<\/APP.*$/);

	}

#  Now process on the xml result

	$Subs->execute("$Subscriber->{reg_id}+$Subscriber->{id}");
	if ($Subs->rows < 1) {
		$Sub->{difsubpaid} = 100;		#  spoof long time ago subscrition
	}
	else {
		$Sub = $Subs->fetchrow_hashref;
	}

#  Does he need to pay next sub?

	if ($Sub->{difsubpaid} > 20 || $Sub->{substatus} !~ /Paid/i) {
		if ($XML_Result =~ /A/i) {
			$Sts = $dbh->do("insert into subscriptions (acct_id,subdatepaid,subinvoiceno,subdescription,subnet,subvat,subauthcode,substatus,submerchantref) values ('$Subscriber->{reg_id}+$Subscriber->{id}',now(),'$Orderid','$Subscription[$Subscriber->{comsublevel}]','$Subrate[$Subscriber->{comsublevel}]','$VAT','$XML_Auth','Paid','$Subscriber->{commerchantref}')");

#  Update to comsubdue value

			$Sts = $dbh->do("update companies set comsubdue=date_add(comsubdue,interval 1 months) where acct_id='$Subscriber->{reg_id}+$Subscriber->{id}'");

########################################  Send paid invoice email  ############################################
		}
		else {
			$Sts = $dbh->do("insert into subscriptions (acct_id,subdatepaid,subinvoiceno,subdescription,subnet,subvat,subauthcode,substatus,submerchantref,subreason) values ('$Subscriber->{reg_id}+$Subscriber->{id}',now(),'$Orderid','$Subscription[$Subscriber->{comsublevel}]',$Subrate[$Subscriber->{comsublevel}]','$VAT','$XML_Auth','Due','$Subscriber->{commerchantref}','$XML_Text')");

#######################################  Send due invoice email  ##########################################
		}
	}
	else {
		if ($XML_Result =~ /A/i) {
			$Sts = $dbh->do("update subscriptions set subdatepaid=now(),substatus='Paid',subauthcode='$XML_Auth',subreason='' where id=$Sub->{id}");
			$Sts = $dbh->do("update companies set comsubdue=date_add(comsubdue,interval 1 months) where acct_id='$Subscriber->{reg_id}+$Subscriber->{id}'");

######################################  send paid email  #############################################
		}
		else {
			if ($Subscriber->{difsubdue} < 0 && $Sub->{substatus} !~ /Overdue/i) {
				$Sts = $dbh->do("update subscriptions set substatus='Overdue' where id=$Sub->{id}");
######################################  send overdue email  ##########################################
			}
			else {
				$Sts = $dbh->do("update subscriptions set substatus='Cancelled' where id=$Sub->{id}");
				$Sts = $dbh->do("update companies set compt_logo='2010-01-01',comsubdue='2010-01-01',comsublevel='00',comsubref='' where reg_id=$Subscriber->{reg_id} and id=$Subscriber->{id}");
				$Sts = $dbh->do("update registrations set regmembership='1' where id=$Subscriber->{reg_id}");
##################################### send cancellation email  #######################################
##################################### do XML delete subscription  ####################################
			}
		}
	}
}
$Subscribers->finish;
$Subs->finish;
$dbh->disconnect;
exit;

