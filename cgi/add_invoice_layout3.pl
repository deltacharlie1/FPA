#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to display the invoice layout

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");
unless ($COOKIE->{NO_ADS}) {
	require "/usr/local/git/fpa/cgi/display_adverts.ph";
	&display_adverts();
}

$Layouts = $dbh->prepare("select * from invoice_layouts where acct_id='$COOKIE->{ACCT}' and id=$ENV{QUERY_STRING}");
$Layouts->execute;
$Layout = $Layouts->fetchrow_hashref;
$Layouts->finish;

$LIs = $dbh->prepare("select * from invoice_layout_items where acct_id='$COOKIE->{ACCT}' and link_id=$ENV{QUERY_STRING} and lidisplay='Y'");
$LIs->execute;
$LI = $LIs->fetchall_arrayref({});
$LIs->finish;

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
        WRAPPER => 'header.tt',
});

$Vars = {
        title => 'Accounts - Invoice Layouts',
	cookie => $COOKIE,
	layout => $Layout,
	items => $LI,
        javascript => '<script type="text/javascript"> 
var errfocus = "";
var uploadparms = "doug";
$(document).ready(function(){
  $(".draggable").draggable();
});
function setfocus() {
  eval("document.getElementById(\'" + errfocus + "\').focus();");
}
</script>',
};

print "Content-Type: text/html\n\n";
$tt->process('add_invoice_layout3.tt',$Vars);

$Companies->finish;
$dbh->disconnect;
exit;

