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

$Companies = $dbh->prepare("select comsublevel,comsubtype,commerchantref,comcardref from companies where reg_id=$Reg_id and id=$Com_id");
$Companies->execute;
$Company = $Companies->fetchrow_hashref;
$Companies->finish;
$dbh->disconnect;

$Membership[0] = 'FreePlus Startup (FREE) - No Adverts';
$Membership[1] = 'FreePlus Startup (FREE)';
$Membership[4] = 'FreePlus Standard (&pound;5.00pm)';
$Membership[6] = 'FreePlus Premium (&pound;10.00pm)';
$Membership[3] = 'FreePlus Bookkeepeer Basic (&pound;5.00pm)';
$Membership[5] = 'FreePlus Bookkeeper Standard (&pound;10.00pm)';
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
	  javascript => '<script type="text/javascript">
function calc_hash(action) {
  $("#sub_action").val(action);
  if (action == "sub" && !$("input[@name=sub]:checked").val()) {
    alert("You have not selected any subscription option!");
  }
  else {
  if (action=="cancel" && ! confirm("Please confirm that you wish to cancel your subscription")) {
    alert("We are delighted that you have decided to stay with us!");
    return false;
  }
  $.ajax({
    url: "/cgi-bin/fpa/returnhash.pl",
    dataType: "json",
    data: "sub=" + $("input:radio[name=sub]:checked").val() + "&action=" + $("#sub_action").val(),
    success: function( data ) {
     document.getElementById("sub_action").value = data[0].action;
     document.getElementById("sub_terminalid").value = data[0].termid;
     document.getElementById("sub_merchantref").value = data[0].merchref;
     document.getElementById("sub_datetime").value = data[0].dte;
     document.getElementById("sub_hash").value = data[0].hash;
     if (/^0/.test($("#sub_current").val()) || action == "card") {
       document.form1.action = "https://cashflows.worldnettps.com/merchant/securecardpage";
     }
     else {
       document.form1.action = "/cgi-bin/fpa/sub_subscribe.pl?" + data[0].merchref + "?" + data[0].oldsubtype;
     }
     document.form1.submit();
   },
   error: function( data,xhr ) {
     alert("Unable to proceed - " + xhr);
   }
 });
 }
}
</script>
<style type="text/css">
.subblock { background-color: #dee5d2; }
</style>'
};

print "Content-Type: text/html\n\n";
$tt->process('2subs.tt',$Vars);
$dbh->disconnect;
exit;

