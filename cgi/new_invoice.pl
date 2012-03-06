#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to display screen for a new invoice

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");
unless ($COOKIE->{NO_ADS}) {
	require "/usr/local/git/fpa/cgi/display_adverts.ph";
	&display_adverts();
}

if ($COOKIE->{PLAN} > 3) {
	($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});

	$Companies = $dbh->prepare("select comlayout from companies where reg_id=$Reg_id and id=$Com_id");
	$Companies->execute;
	$Company = $Companies->fetchrow_hashref;
	$Companies->finish;

	$Layouts = $dbh->prepare("select * from invoice_layouts where acct_id='$COOKIE->{ACCT}' order by id");
	$Layouts->execute;
	$Layout = $Layouts->fetchall_arrayref({});
	$Layouts->finish;
}

$Customers = $dbh->prepare("select id,cusname,cusaddress,cuspostcode,cusregion,cuscontact,cusemail,custerms,cusbalance,cuslimit,cusdefpo,cuscis,cusdefvatrate,cusdefpaymethod,cuslayout from customers where id=? and acct_id=?");
$Customers->execute($ENV{QUERY_STRING},"$COOKIE->{ACCT}");
$Customer = $Customers->fetchrow_hashref;

unless ($Customer->{cuslayout} > 0) { $Customer->{cuslayout} = $Company->{comlayout}; }

$Focus = "srch";
if ($ENV{QUERY_STRING} =~ /^\d+$/) {
	$Focus = "desc";
}

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
        WRAPPER => 'header.tt',
});

$Vars = {
        title => 'Accounts - Customers',
	cookie => $COOKIE,
	company => $Company,
	layouts => $Layout,
        vats => $Vat,
	focus => $Focus,
	invtype => $ENV{QUERY_STRING},
	cus => $Customer,
        javascript => '<script type="text/javascript" src="/js/add_lineitem.js"></script>
<script type="text/javascript">
var errfocus = "";
$(document).ready(function(){
  $("#confirmdialog").dialog({
    bgiframe: true,
    height: 180,
    width: 300,
    autoOpen: false,
    position: [200,100],
    modal: true,
    buttons: {
      "Yes": function() { document.getElementById("x_cus_id").value = "-1"; $(this).dialog("close"); },
      "No": function() { $(this).dialog("close"); }
    },
    close: function() {
      var dg = $("#div_html").html().replace(/\+/gim,"%2B");
      var submit_data = $(".newinvoice").serialize() + "&invtotal=" + escape($("#st").html()) + "&invvat=" + escape($("#vt").html()) + "&invitems=" + escape(dg) + "&submit=Final";
      $.post("/cgi-bin/fpa/save_invoice.pl",submit_data ,function(data) {
        if ( ! /^OK/.test(data)) {
          alert(data);
        }
        else {
          var href = data.split("-");
          location.href = "/cgi-bin/fpa/" + href[1];
       }
      },"text");
    }
  });
  $("#invnextinvdate").datepicker({ minDate: new Date() });
  $("#template").dialog({
    bgiframe: true,
    height: 260,
    width: 400,
    autoOpen: false,
    position: [200,100],
    modal: true,
    buttons: {
      "Save Template": function() {
        if ($("#invtype").val() == "C") {
          $("#dialog").html("<p>You cannot create a template for a Credit Note</p>");
          $("#dialog").dialog("open");
        }
        else { 
          if (validate_form("#form1")) {
            var dg = $("#div_html").html().replace(/\+/igm,"%2B");
            var submit_data = $(".newinvoice").serialize() + "&invtotal=" + escape($("#st").html()) + "&invvat=" + escape($("#vt").html()) + "&invitems=" + escape(dg) + "&submit=Template";
            $.post("/cgi-bin/fpa/save_invoice.pl",submit_data ,function(data) {
              if ( ! /^OK/.test(data)) {
                alert(data);
              }
              else {
                var href = data.split("-");
                location.href = "/cgi-bin/fpa/" + href[1];
              }
            },"text");
          }
          $(this).dialog("close");
        }
      },
      Cancel: function() {
        $(this).dialog("close");
      }
    }
  });
  $("#srch").autocomplete({
    minLength: 0,
    delay: 50,
    source: function (request,response) {
      request.type = "Customers";
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
        document.getElementById("x_invcusemail").value = data.cusemail;
        document.getElementById("x_invcusterms").value = data.custerms;
        document.getElementById("x_invcusref").value = data.cusdefpo;
        document.getElementById("cuscis").value = data.cuscis;
        document.getElementById("selcus").className = "hidden";
        document.getElementById("desc").focus();
      });
    }
  });
  $("#x_invprintdate").datepicker();
  init_rows();
  display_table();
});
function setfocus() {
  eval("document.getElementById(\'" + errfocus + "\').value = \'\';");
  eval("document.getElementById(\'" + errfocus + "\').focus();");
}
function goto_list() {
  if (document.getElementById("x_cus_id").value > 0) {
    location.href = "/cgi-bin/fpa/list_customer_invoices.pl?" + document.getElementById("x_cus_id").value;
  }
  else {
    alert("No Customer selected");
  }
}
function change_invtext(obj) {
  if (obj.value == "S") {
    $(".invtext").each( function() { $(this).html("Invoice"); });
  }
  else {
    $(".invtext").each( function() { $(this).html("Credit Note"); });
  }
}
function submit_details(action) {
  if (action == "Template") {
    $("#template").dialog("open");
  }
  else {
    if (validate_form("#form1")) {
      if (document.getElementById("x_cus_id").value == "" && action == "Final") {
         $("#confirmdialog").dialog("open");
      }
      else {
        var dg = $("#div_html").html().replace(/\+/gim,"%2B");
        var submit_data = $(".newinvoice").serialize() + "&invtotal=" + escape($("#st").html()) + "&invvat=" + escape($("#vt").html()) + "&invitems=" + escape(dg) + "&submit=" + action;
        $.post("/cgi-bin/fpa/save_invoice.pl",submit_data ,function(data) {
          if ( ! /^OK/.test(data)) {
            alert(data);
          }
          else {
            var href = data.split("-");
            location.href = "/cgi-bin/fpa/" + href[1];
         }
        },"text");
      }
    }
  }
}
</script>',
};

print "Content-Type: text/html\n\n";
$tt->process('new_invoice.tt',$Vars);

$Customers->finish;
$dbh->disconnect;
exit;

