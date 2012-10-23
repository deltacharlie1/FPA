#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to display  existing invoices

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

($Inv_id,$Action) = split(/\?/,$ENV{QUERY_STRING});

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");
if ($COOKIE->{PLAN} > 3) {
	$Layouts = $dbh->prepare("select * from invoice_layouts where acct_id='$COOKIE->{ACCT}' order by id");
	$Layouts->execute;
	$Layout = $Layouts->fetchall_arrayref({});
	$Layouts->finish;
}

$Invoices = $dbh->prepare("select invoice_templates.id,cus_id,invcusname,invcusaddr,invcuspostcode,invcusref,date_format(invoice_templates.invprintdate,'%d-%b-%y') as printdate,invcusregion,invcusterms,invcuscontact,invcusemail,invtotal,invvat,invtotal + invvat as tottotal,(invtotal*0.8+invvat) as cistotal,invstatus,invfpflag,invremarks,invitems,invitemcount,cusdefpaymethod,cuscis,invlayout,invrepeatfreq,invnextinv,invlastinv,invemailsubj,invemailmsg from invoice_templates left join customers on (invoice_templates.cus_id=customers.id and invoice_templates.acct_id=customers.acct_id) where invoice_templates.id=$Inv_id and invoice_templates.acct_id='$COOKIE->{ACCT}'");
$Invoices->execute;
$Invoice = $Invoices->fetchrow_hashref;

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
        WRAPPER => 'header.tt',
});

print "Content-Type: text/html\n\n";
$Vars = {
        title => 'Accounts - Invoice Templates',
	cookie => $COOKIE,
	layouts => $Layout,
        vats => $Vat,
	focus => 'desc',
	invoice => $Invoice,
        javascript => '<script type="text/javascript" src="/js/add_lineitem.js"></script>
<script language="JavaScript">
var responseText = "";
var errfocus = "";
$(document).ready(function(){
  $("#x_invprintdate").datepicker();
  init_rows();
  display_table();
});
function setfocus() {
  eval("document.getElementById(\'" + errfocus + "\').value = \'\';");
  eval("document.getElementById(\'" + errfocus + "\').focus();");
}
function submit_details(action) {
  if (validate_form("#form1")) {
    if (document.getElementById("x_cus_id").value == "" && action == "Final") {
       $("#confirmdialog").dialog("open");
    }
    else {
      var dg = $("#div_html").html().replace(/\+/gim,"%2B");
      var submit_data = $(".newinvoice").serialize() + "&invtotal=" + escape($("#st").html()) + "&invvat=" + escape($("#vt").html()) + "&invitems=" + escape(dg) + "&submit=" + action;
      $.post("/cgi-bin/fpa/save_invoice_template.pl",submit_data ,function(data) {
        if ( ! /^OK/.test(data)) {
          $("#dialog").html(data);
          $("#dialog").dialog("open");
        }
        else {
          var href = data.split("-");
          location.href = "/cgi-bin/fpa/" + href[1];
       }
      },"text");
    }
  }
}
</script>'
};

$tt->process('update_invoice_template.tt',$Vars);
$Invoices->finish;
$dbh->disconnect;
exit;

