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

unless ($COOKIE->{NO_ADS}) {
        require "/usr/local/git/fpa/cgi/display_adverts.ph";
        &display_adverts();
}

open(XML,'</usr/local/git/fpa/other/cashflows') || warn "Could not open cashflos file\n";
@Xmlstr = <XML>;
close(XML);

($Termid,$Secret,$URL) = @Xmlstr;
chomp($Termid);
chomp($Secret);
chomp($URL);

$Companies = $dbh->prepare("select comsublevel,comsubtype,commerchantref,comcardref,date_format(comsubdue,'%d-%b-%y') as subdue from companies where reg_id=$Reg_id and id=$Com_id");
$Companies->execute;
$Company = $Companies->fetchrow_hashref;
$Companies->finish;
$dbh->disconnect;

$Membership[1] = 'FreePlus Startup (FREE)';
$Membership[3] = 'FreePlus Bookkeeper Basic (&pound;5.00pm)';
$Membership[4] = 'FreePlus Standard (&pound;5.00pm)';
$Membership[5] = 'FreePlus Bookkeeper Standard (&pound;10.00pm)';
$Membership[6] = 'FreePlus Premium (&pound;10.00pm)';
$Membership[8] = 'FreePlus BookkeepersPremium (&pound;20.00pm)';

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
	WRAPPER => 'header.tt'
        });

$Vars = { cookie => $COOKIE,
	  title => 'Subscriptions',
	  membership => $Membership[$COOKIE->{ACCESS}],
	  company => $Company,
	  termid => $Termid,
	  javascript => '<script type="text/javascript">
function check_select(button) {
  if (button == "S" && ! $("input[@name=sub]:checked").val()) {
    alert("You have not selected any subscription option!");
  }
  else {
    $("#subaction").val(button);
    document.forms["subs_form"].submit();;
 }
}
</script>
<style type="text/css">
.subblock { background-color: #dee5d2; }
</style>'
};

print "Content-Type: text/html\n\n";
$tt->process('subs.tt',$Vars);
$dbh->disconnect;
exit;

