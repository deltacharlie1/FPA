#!/usr/bin/perl

#  The default initial menu displayed at first login

$ACCESS_LEVEL = 0;

# use Checkid;

use Checkid;
$COOKIE =  &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

use DBI;
my $dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");

($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});
$Companies = $dbh->prepare("select companies.comname,comcompleted,regdefaultrows,comnocheques,comvatcontrol,cominvstats,comtxnstats,comnetstats from companies left join registrations using(reg_id) where companies.reg_id=$Reg_id and companies.id=$Com_id");
$Companies->execute;
$Company = $Companies->fetchrow_hashref;
$Companies->finish;

$Coas = $dbh->prepare("select coanominalcode,coabalance from coas where acct_id='$COOKIE->{ACCT}'");
$Coas->execute;
$Coa = $Coas->fetchall_hashref('coanominalcode');
$Coas->finish;

$Vataccruals = $dbh->prepare("select sum(acrvat) from vataccruals where vr_id=0 and acct_id='$COOKIE->{ACCT}'");
$Vataccruals->execute;
($Company->{comvatcontrol}) = $Vataccruals->fetchrow;
$Vataccruals->finish;
 
#  Update the status of any invoices

$Invoices = $dbh->prepare("select to_days(invprintdate),to_days(invduedate),to_days(now()),invtotal,invvat,invpaid,invpaidvat,id from invoices where invstatuscode > '2' and not isnull(invduedate) and acct_id='$COOKIE->{ACCT}'");
$Invoices->execute;
while (@Invoice = $Invoices->fetchrow) {

        if ($Invoice[1] < $Invoice[2]) {
                $Sts = $dbh->do("update invoices set invstatus='Overdue',invstatuscode='9' where id=$Invoice[7] and acct_id='$COOKIE->{ACCT}'");
        }
        elsif (($Invoice[1] - $Invoice[2]) < ($Invoice[1] - $Invoice[0]) * 0.7) {
                $Sts = $dbh->do("update invoices set invstatus='Due',invstatuscode='6' where id=$Invoice[7] and acct_id='$COOKIE->{ACCT}'");
        }
}

#  Get any Reminders

$Reminders = $dbh->prepare("select id,remtext,remcode,remgrade from reminders where acct_id='$COOKIE->{ACCT}' and remstartdate <= curdate() and remenddate >= curdate()");
$Reminders->execute;
$Reminder = $Reminders->fetchall_arrayref({});
$Reminders->finish;

$Invoices = $dbh->prepare("select id as invid,invinvoiceno,invcusname,(invtotal+invvat - invpaid - invpaidvat) as invamount from invoices where invtype='S' and invstatuscode > 6 and acct_id=? order by invprintdate");
$Invoices->execute("$COOKIE->{ACCT}");

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
        WRAPPER => 'header.tt',
});

$Vars = {
        title => 'Accounts - Main Screen',
	cookie => $COOKIE,
        invoices => $Invoices->fetchall_arrayref({}),
	coa => $Coa,
	company => $Company,
	reminders => $Reminder,
        javascript => '<link rel="stylesheet" type="text/css" href="/tango/skin.css" />
<script type="text/javascript" src="/js/jquery.jcarousel.min.js"></script>
<style type="text/css">
.jcarousel-control {
    text-align: center;
}
.jcarousel-control  ul{
    margin:0px;
    padding:0px;
}
.jcarousel-control li {
    display: inline;
    list-style-type: none;
    font-size: 75%;
    text-decoration: none;
    padding: 0 5px;
    margin: 0 0 0px 0;
    border: 1px solid #fff;
    color: #eee;
    background-color: #4088b8;
    font-weight: bold;
}
.jcarousel-control li a {
    color: #eee;
    text-decoration: none;
    font-weight: bold;
    display:inline;
}
.jcarousel-control a:focus,
.jcarousel-control a:active {
    outline: none;
}
</style>
<script type="text/javascript">
$(document).ready(function(){
  var width = (screen.availWidth > 1100) ? 1100 : screen.availWidth;
  var left = parseInt((screen.availWidth - ((screen.availWidth > 1100) ? 1100 : screen.availWidth)) / 2);
  $("#carousel").jcarousel({ 
     visible: 1, 
     scroll: 1, 
     initCallback: function(carousel) { $(".jcarousel-control li").bind("click", function() { 
         carousel.scroll($.jcarousel.intval($(this).text())); 
         return false; 
       });
     },
    itemVisibleInCallback: function(carousel,li,idx,state) { $(".jcarousel-control li").each(function(index) { if (index == idx - 1) { $(this).attr("style","background-color:#800000;"); }});},
    itemVisibleOutCallback: function(carousel,li,idx,state) { $(".jcarousel-control li").each(function(index) { if (index == idx - 1) { $(this).attr("style","background-color:#4088b8;"); }});}

  });
//  self.moveTo(left,0);
//  self.resizeTo(width,screen.availHeight);
});
</script>',
};


print "Content-Type: text/html\n";
print "Set-Cookie: fpa-comname=$Company->{comname}; path=/;\n\n";

$tt->process('dashboard.tt',$Vars);

# print "Bank = " . $Coa{'1200'} . "\n";

$dbh->disconnect;
exit;

