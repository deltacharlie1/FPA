#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to display  existing invoices

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");

$Invoices = $dbh->prepare("select id,cus_id,invcusname,invcusaddr,date_format(invnextinvdate,'%d-%b-%y') as printdate,invcuspostcode,invcusref,invcusregion,invcusterms,invcuscontact,invcusemail,invtotal,invvat,invtotal + invvat as tottotal,invremarks,invitems,invitemcount,invrepeatfreq,invemailmsg from invoice_templates where id=$ENV{QUERY_STRING} and acct_id='$COOKIE->{ACCT}'");
$Invoices->execute;
$Invoice = $Invoices->fetchrow_hashref;

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
        WRAPPER => 'header.tt',
});

if ($COOKIE->{VAT} =~ /N/i) {
	$Line_js = sprintf("<script type=\"text/javascript\" src=\"/js/add_novatitem.js\"></script>\n");
}
else {
	$Line_js = sprintf("<script type=\"text/javascript\" src=\"/js/add_lineitem.js\"></script>\n");
}

print "Content-Type: text/html\n\n";

$Vars = {
	 ads => $Adverts,
        title => 'Accounts - Customers',
	cookie => $COOKIE,
        vats => $Vat,
	focus => 'desc',
	invoice => $Invoice,
        javascript => '<script type="text/javascript" src="/js/jquery-form.js"></script>'
. $Line_js .
'<script language="JavaScript">
var responseText = "";
var errfocus = "";
$(document).ready(function(){
  $("#x_invprintdate").datepicker();
  var options = {
    beforeSubmit: validate,
    success: showResponse
  };
  $("#form1").ajaxForm(options);
});
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
  if(validate_form("form1")) {
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
function setfocus() {
  eval("document.getElementById(\'" + errfocus + "\').value = \'\';");
  eval("document.getElementById(\'" + errfocus + "\').focus();");
}
</script>'
};

$tt->process('update_template.tt',$Vars);

$Invoices->finish;
$dbh->disconnect;
exit;

