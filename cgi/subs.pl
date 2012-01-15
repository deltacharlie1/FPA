#!/usr/bin/perl

$ACCESS_LEVEL = 0;

#  script to display the registration screen tuned to reregistering

#  Terminology buster!

#  1 - commerchantref			=  the Secure Card Merchant Ref (this is an identifier for the card owner)
#  2 - comcardref			=  the reference of the card (this is a reference of the card within the card owner group)
#  3 - comsubtype			=  the subscription being taken out / in operation
#  5 - comsubtype.commerchantref	=  the identifier of a specific subscription for the card owner (not this is MERCHANTREF for
#					   the <ADDSUBSCRIPTION> xml input!!

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});
use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");

$Companies = $dbh->prepare("select comsublevel,comsubtype,commerchantref,comcardref from companies where reg_id=$Reg_id and id=$Com_id");
$Companies->execute;
$Company = $Companies->fetchrow_hashref;
$Companies->finish;
$dbh->disconnect;

$Membership[0] = 'FreePlus Startup (FREE)';
$Membership[1] = 'FreePlus Standard (&pound;5.00pm)';
$Membership[2] = 'FreePlus Premium (&pound;10.00pm)';

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib']
        });

$Vars = { cookie => $COOKIE,
	  membership => $Membership[$Company->{comsublevel}],
	  company => $Company
};

print "Content-Type: text/html\n\n";
$tt->process('subs.tt',$Vars);
$dbh->disconnect;
exit;

