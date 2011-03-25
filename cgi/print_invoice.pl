#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to display  existing invoices

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);
($Inv_id,$Firsttime) = split(/\?/,$ENV{QUERY_STRING});

use DBI;
my $dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");

$Invoices = $dbh->prepare("select invoices.id as id,cus_id,invinvoiceno,invcusname,invtype,invcuscontact,invcusemail,invstatuscode,cusemailmsg from invoices left join customers  on (cus_id=customers.id and invoices.acct_id=customers.acct_id) where invoices.id=? and invoices.acct_id=?");
$Invoices->execute($Inv_id,"$COOKIE->{ACCT}");
$Invoice = $Invoices->fetchrow_hashref;
$Invoice->{firsttime} = $Firsttime;	# required otherwise firsttime is undefined

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
        WRAPPER => 'header.tt',
});

$Vars = {
        title => 'Accounts - Customers',
	cookie => $COOKIE,
	invoice => $Invoice,
        javascript => '<script type="text/javascript" src="/js/jquery-form.js"></script> 
<script language="JavaScript">
var responseText = "";
var errfocus = "";
$(document).ready(function(){
  var options = {
    beforeSubmit: validate,
    success: showResponse
  };
  $("#form1").ajaxForm(options);
});
function showResponse(responseText, statusText) {
  if (/OK/i.test(responseText)) {
    var href = responseText.split("-");
    alert(href[1]);
    location.href = "/cgi-bin/fpa/" + href[2];
  }
  else {
    document.getElementById("dialog").innerHTML = responseText;
    $("#dialog").dialog("open");
  }
}
function validate(formData,jqForm,options) {
 return validate_form("#form1");
}
function delete_invoice() {
  $.post("/cgi-bin/fpa/delete_invoice.pl", { id: "'.$Invoice->{id}.'" }, function(data) {
    if (/OK/.test(data)) {
      location.href = "/cgi-bin/fpa/list_customer_invoices.pl?' . $Invoice->{cus_id} . '";
    }
    else {
      responseText = data;
      document.getElementById("dialog").innerHTML = responseText;
      $("#dialog").dialog("open");
    }
  });
}
</script>',
};

print "Content-Type: text/html\n\n";
$tt->process('print_invoice.tt',$Vars);

$Invoices->finish;
$dbh->disconnect;
exit;

