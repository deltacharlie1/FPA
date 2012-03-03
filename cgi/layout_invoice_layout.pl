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

$LIs = $dbh->prepare("select * from invoice_layout_items where acct_id='$COOKIE->{ACCT}' and link_id=$ENV{QUERY_STRING} and lidisplay='Y' order by lifldcode");
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
        javascript => '<style type="text/css">
.draggable {
	position:absolute;
        border:1px solid #248eb1;
        background-color: #cee1e7;
        height: 16px;
	left: 5px;
	padding: 0 3px;
	font-size:10px;
	vertical-align:middle;
}
.bleft { border-left: 2px solid #b12435; }
.bright { border-right: 2px solid #b12435; }
.bcentre { border-left: 2px solid #b12435;
         border-right: 2px solid #b12435;
}
</style>
<script type="text/javascript"> 
var errfocus = "";
var uploadparms = "";
var itemwidth = "";
var itemheight = "";
$(document).ready(function(){
  $(".draggable").draggable({
    cursor     : "pointer",
    start      : function() {
                   itemwidth = $(this).width()+30;
                   $("#notifier").toggle();
                 },
    stop       : function() { $("#notifier").toggle(); },
    drag       : function (event,ui) {
                   $("#notifier").css({ "top":ui.position.top + 2, "left":ui.position.left + itemwidth });
                   if (/53/.test($(this).css("border-right-color"))) {
                     $("#notifier").html((ui.position.left+itemwidth) + " x " + ui.position.top);
                   }
                   else {
                     $("#notifier").html(ui.position.left + " x " + ui.position.top);
                   }
                 }
  });
  $(".resizable").resizable({
    start      : function() {
                   itemwidth = $(this).width()+30;
                   itemheight = $(this).height()+10;
                   $("#notifier").toggle();
                 },
    stop       : function() { $("#notifier").toggle(); },
    resize     : function (event,ui) {
                   itemwidth = $(this).width()+30;
                   itemheight = $(this).height()+10;
                   $("#notifier").css({ "top":ui.position.top + itemheight, "left":ui.position.left + itemwidth });
                   $("#notifier").html((ui.position.left+itemwidth)  + " x " + (ui.position.top+itemheight));
                 }
  });
});
function setfocus() {
  eval("document.getElementById(\'" + errfocus + "\').focus();");
}
function save_it() {
var data = "";
  $(".draggable").each(function() {
    data = data + $(this).attr("id") + "-" + $(this).position().top + "-" + $(this).position().left + "-" + $(this).width() + "-" + $(this).height() + "\\n";
  });
  $("#data").val(data);

}
</script>',
};

print "Content-Type: text/html\n\n";
$tt->process('layout_invoice_layout.tt',$Vars);

$dbh->disconnect;
exit;

