#!/usr/bin/perl

#  The default initial menu displayed at first login

$ACCESS_LEVEL = 0;

# use Checkid;

use Checkid;
$COOKIE =  &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

if ($ENV{QUERY_STRING} =~ /INV/) {
	$Invite_js =<<EOD;

  \$("#dialog").dialog("option","title","Information");
  \$("#dialog").html("Your accounts may now be managed by your bookkeeper");
  \$("#dialog").dialog("open");
EOD
}

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");
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
	 ads => $Adverts,
        title => 'Accounts - Main Screen',
	cookie => $COOKIE,
        invoices => $Invoices->fetchall_arrayref({}),
	coa => $Coa,
	company => $Company,
	reminders => $Reminder,
        javascript => '<style type="text/css">
.image_carousel {
	padding: 2px 0 15px 30px;
	position: relative;
}
.image_carousel img {
	border: 1px solid #ccc;
	background-color: white;
	padding: 3px;
	margin: 7px;
	display: block;
	float: left;
	width:280px;
	height:132px;
}
a.prev, a.next {
	background: url(/icons/dash.png) no-repeat transparent;
	width: 45px;
	height: 50px;
	display: block;
	position: absolute;
	top: 65px;
}
a.prev {			left: -10px;
					background-position: 0 0; }
a.prev:hover {		background-position: 0 -50px; }
a.prev.disabled {	background-position: 0 -100px !important;  }
a.next {			right: -10px;
					background-position: -50px 0; }
a.next:hover {		background-position: -50px -50px; }
a.next.disabled {	background-position: -50px -100px !important;  }
a.prev.disabled, a.next.disabled {
	cursor: default;
}

a.prev span, a.next span {
	display: none;
}
.pagination {
	text-align: center;
	margin-right:30px;
}
.pagination a {
	background: url(/icons/dash.png) 0 -300px no-repeat transparent;
	width: 15px;
	height: 15px;
	margin: 0 5px 0 0;
	display: inline-block;
}
.pagination a.selected {
	background-position: -25px -300px;
	cursor: default;
}
.pagination a span {
	display: none;
}
.clearfix {
	float: none;
	clear: both;
}
</style>
<script type="text/javascript">
$(document).ready(function(){
  var width = (screen.availWidth > 1100) ? 1100 : screen.availWidth;
  var left = parseInt((screen.availWidth - ((screen.availWidth > 1100) ? 1100 : screen.availWidth)) / 2);
$("#foo5").carouFredSel({
	circular	: false,
	infinite	: false,
	auto 		: false,
	prev : {
		button		: "#foo5_prev",
		key		: "left",
		items		: 1,
		easing		: "easeInOutCubic",
		duration	: 750
	},
	next : {
		button		: "#foo5_next",
		key		: "right",
		items		: 1,
		easing		: "easeInQuart",
		duration	: 1500
	},
	pagination : {
		container	: "#foo5_pag",
		keys		: true,
		easing		: "easeOutBounce",
		duration	: 3000
	}
});'.$Invite_js.'
//  self.moveTo(left,0);
//  self.resizeTo(width,screen.availHeight);
});
</script>'
};


print "Content-Type: text/html\n";
print "Set-Cookie: fpa-comname=$Company->{comname}; path=/;\n\n";

$tt->process('dashboard.tt',$Vars);

# print "Bank = " . $Coa{'1200'} . "\n";

$dbh->disconnect;
exit;

