#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to display  existing purchase invoices

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

($Inv_id,$Action) = split(/\?/,$ENV{QUERY_STRING});

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");

$Invoices = $dbh->prepare("select id,cus_id,invcusname,invtype,invcusaddr,date_format(invprintdate,'%d-%b-%y') as invprintdate,date_format(invduedate,'%d-%b-%y') as invduedate,invinvoiceno,invcuspostcode,invcusref,invcusregion,invcusterms,invcuscontact,invcusemail,invtotal,invvat,invtotal + invvat as tottotal,invstatus,invfpflag,invremarks,invitems,invitemcount,to_days(invprintdate) as printdays,to_days(invduedate) as duedays,invstatuscode,invpaid + invpaidvat as totpaid,date_format(invpaiddate,'%d-%b-%y') as invpaiddate,to_days(invprintdate) - to_days(now()) as elapsed_days from invoices where id=? and acct_id=?");
$Invoices->execute($Inv_id,"$COOKIE->{ACCT}");
$Invoice = $Invoices->fetchrow_hashref;

#  See if we have any uploaded documents

$Images = $dbh->prepare("select id,imgfilename,imgdesc,imgthumb,date_format(imgdate_saved,'%d-%b-%y') as imgdate from images where acct_id='$COOKIE->{ACCT}' and link_id=$Inv_id");
$Images->execute;

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
        WRAPPER => 'header.tt',
});

if ($COOKIE->{VAT} =~ /N/i) {
	$Line_js = sprintf("<script language=\"Javascript\" type=\"text/javascript\" src=\"/js/add_lineitem.js\"></script>\n");
}
else {
	$Line_js = sprintf("<script language=\"Javascript\" type=\"text/javascript\" src=\"/js/add_lineitem.js\"></script>\n");
}

if ($Action =~ /P/i) {
	$Focus = "location.href='/cgi-bin/fpa/pdf_invoice.pl?$Inv_id';";
}
else {
	$Focus = "";
}

$Vars = {
	 ads => $Adverts,
        title => 'Accounts - Suppliers',
	cookie => $COOKIE,
        vats => $Vat,
	focus => $Focus,
	invoice => $Invoice,
	images => $Images->fetchall_arrayref({}),
        javascript => '<script type="text/javascript" src="/js/jquery-form.js"></script>'
. $Line_js .
'<link rel="stylesheet" href="/css/jquery.flexbox.css" type="text/css">
<script src="/js/jquery.flexbox.js" type="text/javascript"></script>
<script language="JavaScript">
var responseText = "";
var errfocus = "";
$(document).ready(function(){
  $("#uploadifydesc").focus();
  $("#pufile").uploadify ({
    "uploader"       : "/js/uploadify.swf",
    "script"         : "/cgi-bin/fpa/uploadify.pl",
    "cancelImg"      : "/js/cancel.png",
    "buttonText"     : "Select & Save",
    "onComplete"     : function(a,b,c,d,e) { window.location.reload(true); },
    "onSelectOnce"   : function(event,data) { $("#pufile").uploadifySettings("scriptData",{"desc" : document.getElementById("uploadifydesc").value }); },
    "fileExt"        : "*.pdf;*.jpg;*.png",
    "fileDesc"       : "PDF or Image Files (*.pdf,*.jpg,*.png)",
    "scriptData"     : {"cookie" : "'.$COOKIE->{COOKIE}.'", "doc_type" : "INV", "doc_rec" : "'.$Invoice->{id}.'" },
    "sizeLimit"      : '.$COOKIE->{UPLDS}.',
    "expressInstall" : "/js/expressInstall.swf",
    "onError"        : function(event, ID, fileObj, errorObj) {
         alert(errorObj.type+"::"+errorObj.info);
      },
    "auto"           : true
  });
  $("#cancelreason").dialog({
    bgiframe: true,
    autoOpen: false,
    position: [200,100],
    height: 200,
    width: 400,
    modal: true,
    buttons: {
      "Void Invoice": function() {
        if(document.getElementById("voidmsg").value == "") {
          $("#dialog").html("You must enter a reason for voiding this invoice");
          $("#dialog").dialog("open");
        }
        else {
          $.post("/cgi-bin/fpa/cancel_purchase_invoice.pl", $("form#fcancelreason").serialize(),function(data) {
            if (/OK/.test(data)) {
              location.href = "/cgi-bin/fpa/list_purchases.pl?' . $Invoice->{cus_id} . '";
            }
            else {
              responseText = data;
              $("#dialog").html(responseText);
              $("#dialog").dialog("open");
            }
          });
        }
      },
      Cancel: function() {
        $(this).dialog("close");
      }
    }
  });
  $("#invprintdate").datepicker();
  var options = {
    beforeSubmit: validate,
    success: showResponse
  };
  $("#form1").ajaxForm(options);
});
function cancel_invoice(invid) {
  if ('.$Invoice->{totpaid}.' != 0) {
    $("#dialog").html("This purchase invoice is at least part-paid.<p>You must first cancel the payment (go to <b>\'Money\'->\'List Transactions\'</b> and double click on the elevant entry)");
    $("#dialog").dialog("open");
  }
  else {
    $("#cancelreason").dialog("open");
    document.getElementById("cancelmsg").focus();
  }
}
function showResponse(responseText, statusText) {
  if (/OK/i.test(responseText)) {
    var href = responseText.split("-");
    location.href = "/cgi-bin/fpa/" + href[1];
  }
  else {
    $("#dialog").html(responseText);
    $("#dialog").dialog("open");
    return false;
  }
}
function validate(formData,jqForm,options) {
  if(validate_form("#form1")) {
//  Stuff the pass through input fields

    for (i=0; i<formData.length; i++) {
      if (formData[i].name == "invitems") {
        formData[i].value = $("#div_html").html();
      }
      if (formData[i].name == "invtotal") {
        formData[i].value = $("#st").html();
      }
      if (formData[i].name == "invvat") {
        formData[i].value = $("#vt").html();
      }
    }
  }
}
function pudel(id) {
  $.get("/cgi-bin/fpa/delete_attach.pl", { id: id }, function(data) { window.location.reload(true); });
}
</script>',
};

print "Content-Type: text/html\n\n";
$tt->process('final_purchase.tt',$Vars);
$Images->finish;
$Invoices->finish;
$dbh->disconnect;
exit;

