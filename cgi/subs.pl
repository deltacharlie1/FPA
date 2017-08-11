#!/usr/bin/perl

$ACCESS_LEVEL = 0;

#  script to display the registration screen tuned to reregistering

#  Terminology buster!

#  1 - commandateref			=  the Secure Card Merchant Ref (this is an identifier for the card owner)
#  2 - compayref			=  the reference of the card (this is a reference of the card within the card owner group)
#  3 - comsubtype			=  the subscription being taken out / in operation
#  5 - comsubtype.commandateref	=  the identifier of a specific subscription for the card owner (not this is MERCHANTREF for
#					   the <ADDSUBSCRIPTION> xml input!!

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});
use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");

$Companies = $dbh->prepare("select comsublevel,comsubtype,commandateref,compayref,date_format(comsubdue,'%d-%b-%y') as subdue from companies where reg_id=$Reg_id and id=$Com_id");
$Companies->execute;
$Company = $Companies->fetchrow_hashref;

$Membership[0] = 'FreePlus Startup (FREE)';
$Membership[1] = 'FreePlus Bookkeeper Basic (&pound;5.00pm)';
$Membership[2] = 'FreePlus Standard (&pound;5.00pm)';
$Membership[3] = 'FreePlus Bookkeeper Standard (&pound;10.00pm)';
$Membership[4] = 'FreePlus Premium (&pound;10.00pm)';
$Membership[5] = 'FreePlus BookkeepersPremium (&pound;20.00pm)';

if ($Company->{comsubtype} eq '00') {
	$COOKIE->{ACCESS} = '1';
}

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
	WRAPPER => 'header.tt'
        });

$Vars = {
	 ads => $Adverts, cookie => $COOKIE,
	  title => 'Subscriptions',
	  membership => $Membership[$Company->{comsubtype}],
	  company => $Company,
	  javascript => '<script type="text/javascript">
function check_select(button) {
  if (button == "S" && ! $("input[@name=sub]:checked").val()) {
    alert("You have not selected any subscription option!");
  }
  else {
    if (button == "T") {
        $("#subaction").val(button);
        $("#subs_form").attr("action","/cgi-bin/fpa/gclv2subs.pl");
        document.forms["subs_form"].submit();
    }
    else {
      if (button == "X") {
        $("#subaction").val(button);
        $("#subs_form").attr("action","/cgi-bin/fpa/gclv2subs.pl");
        document.forms["subs_form"].submit();
      }
      else {
        $("#subaction").val(button);
        document.forms["subs_form"].submit();
      }
    }
 }
}
</script>
<style type="text/css">
.subblock { background-color: #dee5d2; }
</style>'
};

print "Content-Type: text/html\n\n";
$tt->process('subs.tt',$Vars);
$Companies->finish;
$dbh->disconnect;
exit;

