#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to display the invoice layout

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");

$Form_id = $ENV{QUERY_STRING};

if ($Form_id < 1) {

#  It must be a new one so find the last saved layout

	$Layouts = $dbh->prepare("select id from invoice_layouts where acct_id='$COOKIE->{ACCT}' order by id desc limit 1");
	$Layouts->execute;
	@Layout = $Layouts->fetchrow;
	$Layouts->finish;
	$Form_id = $Layout[0];
}

$Layouts = $dbh->prepare("select * from invoice_layouts where acct_id='$COOKIE->{ACCT}' and id=$Form_id");
$Layouts->execute;
$Layout = $Layouts->fetchrow_hashref;
$Layouts->finish;

$LIs = $dbh->prepare("select * from invoice_layout_items where acct_id='$COOKIE->{ACCT}' and link_id=$Form_id order by lifldcode");
$LIs->execute;
$Next_item = $LIs->rows;
$Next_item++;
$LI = $LIs->fetchall_arrayref({});
$LIs->finish;

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
        WRAPPER => 'header.tt',
});

$Vars = {
	 ads => $Adverts,
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
var itemid = "";
var itemwidth = "";
var itemheight = "";
var next_item = '.$Next_item.'
$(document).ready(function(){
  $("#laysettings").dialog({
    bgiframe: true,
    autoOpen: false,
    position: [200,100],
    height: 300,
    width: 280,
    modal: true,
    buttons: {
      "Save Settings": function() {
        $("#"+itemid).removeClass("bleft bcentre bright");
        $("#"+itemid).addClass($("#layjust").val());
        var left = $("#layleft").val();
        if ($("#"+itemid).hasClass("bcentre")) {
          left = $("#layleft").val() - parseInt(($("#"+itemid).width() - 30)/2);
        }
        if ($("#"+itemid).hasClass("bright")) {
          left = $("#layleft").val() - $("#"+itemid).width() - 30;
        }
        $("#"+itemid).css({"top": $("#laytop").val()+"px", "left": left+"px", "height": $("#laysize").val()+"px", "font-size": $("#laysize").val()+"px", "font-weight": $("#laybold").val() } );
        $(this).dialog("close");
      },
      Cancel: function() {
        $(this).dialog("close");
      }
    }
  });
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
                     $("#notifier").html((ui.position.left+itemwidth) + " x " + parseInt(ui.position.top));
                   }
                   else {
                     $("#notifier").html(ui.position.left + " x " + parseInt(ui.position.top));
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
    var just = "l";
    if ($(this).hasClass("bcentre")) {
      just = "c";
    }
    else {
      if ($(this).hasClass("bright")) {
        just = "r";
      }
    }
    data = data + $(this).attr("id") + "-" + $(this).position().top + "-" + $(this).position().left + "-" + $(this).width() + "-" + $(this).height() + "-" + $(this).css("font-weight") + "-" + just + "\\n";
  });
  $("#data").val(data);
}
function open_settings(id) {
  itemid = id;
  var dir = "";
  if (/rgb\(177/i.test($("#"+id).css("border-right-color"))) {
    $("#laydir").text("Right: ");
    dir = "right";
    var left = $("#"+id).position().left * 1;
    var width = $("#"+id).width() * 1;
    var right = left+width + 30;
    $("#layleft").val(right);
  }
  else {
    $("#laydir").text("Left: ");
    dir = "left";
    $("#layleft").val($("#"+id).position().left);
  }
  $("#laytop").val($("#"+id).position().top);
  $("#laysize").val($("#"+id).height());
  $("#laybold").val($("#"+id).css("font-weight"));
  $("#laytop").focus();  
  if ($("#"+id).hasClass("dupable")) {
    $("#dupable").show();
  }
  else {
    $("#dupable").hide();
  }
  $("#laysettings").dialog("open");
}
function dup_this() {
  var $clone = $("#"+itemid)
      .clone()
      .width($("#"+itemid).width())
      .css("top",$("#"+itemid).position().top+15)
      .css("left",$("#"+itemid).position().left+15)
      .css("z-index","999999")
      .height($("#"+itemid).height())
      .attr("id", itemid+next_item)
      .draggable();
  next_item = next_item + 1;
  $("#invlayout").prepend( $clone );   
  $("#laysettings").dialog("close");
}
</script>',
};

print "Content-Type: text/html\n\n";
$tt->process('layout_invoice_layout.tt',$Vars);

$dbh->disconnect;
exit;

