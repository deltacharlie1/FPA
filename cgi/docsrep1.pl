#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to display uploaded documents

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");
unless ($COOKIE->{NO_ADS}) {
	require "/usr/local/git/fpa/cgi/display_adverts.ph";
	&display_adverts();
}

if ($COOKIE->{ACCESS} > 6) {
	$Max = 15728640;
}
elsif ($COOKIE->{ACCESS} > 5) {
	$Max = 4194304;
}
else {
	$Max = 0;
}

#  Get a start and end (now) date

$Dates = $dbh->prepare("select date_format(date_sub(now(),interval 6 month),'%d-%b-%y'),date_format(now(),'%d-%b-%y')");
$Dates->execute;
($Start_date,$End_date) = $Dates->fetchrow;
$Dates->finish;

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
	WRAPPER => 'header.tt'
});

$Vars = {
	 ads => $Adverts,
        title => 'Accounts - List Documents',
	cookie => $COOKIE,
	focus => 'imgfilename',
        startdate => $Start_date,
        enddate => $End_date,
	max => $Max,
	remaining => $COOKIE->{UPLDS},
        javascript => '<script type="text/javascript"> 
$(document).ready(function(){
  $("#startdate").datepicker({ minDate: new Date(2000,01 - 1,01) });
  $("#enddate").datepicker({ minDate: new Date(2000,01 - 1,01) });
  $("#pudialog").dialog({
    bgiframe: true,
    height: 200,
    width: 450,
    autoOpen: false,
    position: [200,100],
    close: function(a,b) { window.location.reload(true); },
    modal: true
  });
  $("#changedesc").dialog({
    bgiframe: true,
    autoOpen: false,
    position: [200,100],
    height: 200,
    width: 400,
    modal: true,
    buttons: {
      "Change Description": function() {
        $.post("/cgi-bin/fpa/change_doc_desc.pl", $("#fchangedesc").serialize(),function(data) {
          if ( ! /^OK/.test(data)) {
            alert(data);
          }
          window.location.reload(true);
        },"text");
        $("td").removeClass("error");
        $(this).dialog("close");
      },
      Cancel: function() {
        $("td").removeClass("error");
        $(this).dialog("close");
      }
    }
  });
  redisplay("S");
});
function change_desc(obj,id,olddesc) {
  $(obj).addClass("error");
  document.getElementById("cd_id").value = id;
  document.getElementById("newdesc").value = olddesc;
  $("#changedesc").dialog("open");
}
function display_puform() {
  $("#pufile").uploadify ({
    "uploader"       : "/js/uploadify.swf",
    "script"         : "/cgi-bin/fpa/uploadify.pl",
    "cancelImg"      : "/js/cancel.png",
    "buttonText"     : "Upload Document",
    "fileExt"        : "*.pdf;*.jpg;*.png",
    "fileDesc"       : "PDF or Image Files (*.pdf,*.jpg,*.png)",
    "sizeLimit"      : '.$COOKIE->{UPLDS}.',
    "expressInstall" : "/js/expressInstall.swf",
    "onSelectOnce"   : function(event,data) { $("#pufile").uploadifySettings("scriptData",{"desc" : document.getElementById("docdesc").value }); },
    "fileDesc"       : "PDF or Image Files (*.pdf,*.jpg,*.png)",
    "scriptData"     : {"cookie" : "'.$COOKIE->{COOKIE}.'", "doc_type" : "OTHER", "doc_rec" : "NULL" },
    "onSelect"       : function(event,ID,fileobj) {
                         if (document.getElementById("docdesc").value.length < 1) {
                           alert("You must enter a file description");
                           document.getElementById("docdesc").focus();
                           return false;
                         }
                         else {
                           return true;
                         }
                      },
    "onComplete"     : function(a,b,c,d,e) { document.getElementById("docdesc").value = ""; $("#pudialog").dialog("close"); },
    "auto"           : true
  });
  $("#pudialog").dialog("open");
  document.getElementById("docdesc").focus();
}

function docdel(id) {
  $.get("/cgi-bin/fpa/delete_attach.pl", { id: id }, function(data) { window.location.reload(true); });
}
function get_results(action) {
  document.getElementById("action").value = action;
  $.get("/cgi-bin/fpa/docsrep2.pl",$("form#form1").serialize() ,function(data) {
    var parts = data.split("\t");
    document.getElementById("numrows").value = parts[0];
    document.getElementById("offset").value = parts[1];
    document.getElementById("action").value = "S";
    $("#results").html(parts[4]);
  });
}
function redisplay(action) {
  if (/^\d+$/.test(action)) {
    if ((action - 1) * document.getElementById("rows").value < document.getElementById("numrows").value) {
      get_results(action);
    }
    else {
      alert("Page count is too high");
    }
  }
  else {
    get_results(action.substring(0,1));
  }
}
</script>'
};

print "Content-Type: text/html\n\n";
$tt->process('docsrep1.tt',$Vars);

$dbh->disconnect;
exit;

