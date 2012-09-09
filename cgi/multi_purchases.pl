#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to display Contact Details (for eventual updating)

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");
unless ($COOKIE->{NO_ADS}) {
	require "/usr/local/git/fpa/cgi/display_adverts.ph";
	&display_adverts();
}


$Customers = $dbh->prepare("select id,cusname,cusaddress,cuspostcode,cusregion,custel,cuscontact,cusemail,custerms,cusbalance,cuscredit,cuslimit,cusdefpaymethod from customers where id=? and acct_id=?");
$Customers->execute($ENV{QUERY_STRING},"$COOKIE->{ACCT}");

$Invoices = $dbh->prepare("select id as invid,invinvoiceno,invdesc,date_format(invprintdate,'%d-%b-%y') as invprintdate,date_format(invduedate,'%d-%b-%y') as invduedate,invtotal,invvat,(invtotal+invvat-invpaid-invpaidvat) as invdue,invstatus,to_days(invprintdate) as printdays,to_days(invduedate) as duedays from invoices where cus_id=? and acct_id=? and invstatuscode > 2 order by invtype,invstatuscode desc,invprintdate desc");
$Invoices->execute($ENV{QUERY_STRING},"$COOKIE->{ACCT}");
$Numrows = $Invoices->rows;
$Rows = 24;
$Offset = 0;

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
        WRAPPER => 'header.tt',
});

$Vars = {
	 ads => $Adverts,
        title => 'Accounts - Suppliers',
	cookie => $COOKIE,
	cus => $Customers->fetchrow_hashref,
	invoices => $Invoices->fetchall_arrayref({}),
	focus => 'txnamount',
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
  $("#i_invprintdate").datepicker();
});
function showResponse(responseText, statusText) {
  if (/OK/i.test(responseText)) {
    var href = responseText.split("-");
//    alert("Payment Recorded");
    location.href = "/cgi-bin/fpa/" + href[1];
  }
  else {
    $("#dialog").html(responseText);
    $("#dialog").dialog("open");
  }
}
function validate(formData,jqForm,options) {
  if(validate_form("#form1")) {
    var none_checked = true;
    $("input:checkbox").each(function() {
      if (this.checked) {
        none_checked = false;
      }
    });
    if (none_checked) {
      return confirm("No invoices have been selected.\\nContinue anyway?");
    }
    else {
      var tot = parseFloat($("#totamt").html());
      var amt = parseFloat(document.getElementById("i_txnamount").value);
      if (tot != amt) {
        return confirm("Total value of selected invoices does not equal the amount being paid.\\nContinue anyway?");
      }
    }
  }
}
function update_tot(obj) {
  var tot = parseFloat($("#totamt").html());
  var amt = parseFloat(obj.value);
  if (obj.checked) {
    tot = (0 - tot + amt).toFixed(2);
  }
  else {
    tot = (0 - tot - amt).toFixed(2);
  }
  $("#totamt").html(tot.replace(/-/g,""));
}
</script>',
};

print "Content-Type: text/html\n\n";
$tt->process('multi_purchases.tt',$Vars);

$Customers->finish;
$Invoices->finish;
$dbh->disconnect;
exit;

