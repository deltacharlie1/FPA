#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to display screen for a new purchases

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");
unless ($COOKIE->{NO_ADS}) {
	require "/usr/local/git/fpa/cgi/display_adverts.ph";
	&display_adverts();
}


$Coas = $dbh->prepare("select coanominalcode,coadesc from coas where (coatype='Expenses' or coadesc like '%Assets%') and acct_id='$COOKIE->{ACCT}' order by coatype desc");
$Coas->execute;
$Coa = $Coas->fetchall_arrayref({});
$Coas->finish;

$Customers = $dbh->prepare("select id,cusname,cusaddress,cuspostcode,cusregion,cuscontact,cusemail,custerms,cusbalance,cuslimit,cusdefcoa from customers where id=? and acct_id=?");
$Customers->execute($ENV{QUERY_STRING},"$COOKIE->{ACCT}");

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
        WRAPPER => 'header.tt',
});

$Vars = {
        title => 'Accounts - Suppliers',
	cookie => $COOKIE,
        vats => $Vat,
	coas => $Coa,
	focus => 'desc',
	cus => $Customers->fetchrow_hashref,
        javascript => '<script type="text/javascript" src="/js/jquery-form.js"></script>
<script type="text/javascript" src="/js/add_lineitem.js"></script>
<script type="text/javascript">
var responseText = "";
var errfocus = "";
$(document).ready(function(){
  $("#srch").autocomplete({
    minLength: 1,
    delay: 50,
    source: function (request,response) {
      request.type = "Suppliers";
      $.ajax({
        url: "/cgi-bin/fpa/autosuggest.pl",
        dataType: "json",
        data: request,
        success: function( data ) {
          response (data);
        }
      });
    },
    select: function(event, ui) {
      $.get("/cgi-bin/fpa/getcustomer.pl",{ id: ui.item.id }, function(data) {
        document.getElementById("x_cus_id").value = data.id;
        document.getElementById("x_invcusname").value = data.cusname;
        document.getElementById("x_invcusaddr").value = data.cusaddress;
        document.getElementById("x_invcuspostcode").value = data.cuspostcode;
        document.getElementById("x_invcusregion").value = data.cusregion;
        document.getElementById("x_invcuscontact").value = data.cuscontact;
        document.getElementById("x_invcusref").value = data.cusdefpo;
        document.getElementById("selcus").className = "hidden";
        document.getElementById("desc").focus();
      });
    }
  });
  $("#x_invprintdate").datepicker();
  var options = {
    beforeSubmit: validate,
    success: showResponse
  };
  $("#form1").ajaxForm(options);
  init_rows();
  display_table();
});
function showResponse(responseText, statusText) {
  if (/OK/i.test(responseText)) {
    var href = responseText.split("-");
    location.href = "/cgi-bin/fpa/" + href[1];
  }
  else {
    document.getElementById("dialog").innerHTML = responseText;
    $("#dialog").dialog("open");
    return false;
  }
}
function validate(formData,jqForm,options) {
  if(validate_form("#form1")) {
//  Stuff the pass through input fields

    for (i=0; i<formData.length; i++) {
      if (formData[i].name == "invitems") {
        formData[i].value = document.getElementById("div_html").innerHTML;
      }
      if (formData[i].name == "invtotal") {
        formData[i].value = document.getElementById("st").innerHTML;
      }
      if (formData[i].name == "invvat") {
        formData[i].value = document.getElementById("vt").innerHTML;
      }
    }
  }
}
function goto_list() {
  if (document.getElementById("x_cus_id").value > 0) {
    location.href = "/cgi-bin/fpa/list_supplier_purchases.pl?" + document.getElementById("x_cus_id").value;
  }
  else {
    alert("No Customer selected");
  }
}
</script>',
};

print "Content-Type: text/html\n\n";
$tt->process('new_purchase.tt',$Vars);

$Customers->finish;
$dbh->disconnect;
exit;

