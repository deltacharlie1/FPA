#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to display  existing invoices

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

($Inv_id,$Action) = split(/\?/,$ENV{QUERY_STRING});

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");
unless ($COOKIE->{NO_ADS}) {
	require "/usr/local/git/fpa/cgi/display_adverts.ph";
	&display_adverts();
}


$Invoices = $dbh->prepare("select invoices.id,cus_id,invcusname,invtype,invcusaddr,date_format(invprintdate,'%d-%b-%y') as invprintdate,date_format(invduedate,'%d-%b-%y') as invduedate,invinvoiceno,invcuspostcode,invcusref,invcusregion,invcusterms,invcuscontact,invcusemail,invtotal,invvat,invtotal + invvat as tottotal,invcistotal,invcistotal-invvat as cistotal,invstatus,invfpflag,invremarks,invitems,invitemcount,to_days(invprintdate) as printdays,to_days(invduedate) as duedays,invstatuscode,invpaid + invpaidvat as totpaid,date_format(invpaiddate,'%d-%b-%y') as invpaiddate,cusdefpaymethod,cuscis,cusdefvatrate,cusdefpaymethod from invoices left join customers on (invoices.cus_id=customers.id and invoices.acct_id=customers.acct_id) where invoices.id=$Inv_id and invoices.acct_id='$COOKIE->{ACCT}'");
$Invoices->execute;
$Invoice = $Invoices->fetchrow_hashref;
$Invoice->{firsttime} = $Action;

$ITs = $dbh->prepare("select date_format(inv_txns.itdate,'%d-%b-%y') as itdate,inv_txns.itnet,inv_txns.itvat,coadesc,format(inv_txns.itnet + inv_txns.itvat,2) as ittot,txnremarks from inv_txns left join coas on (inv_txns.itmethod=coanominalcode), inv_txns a left join transactions on (a.txn_id=transactions.id) where inv_txns.id=a.id and inv_txns.acct_id='$COOKIE->{ACCT}' and (coas.acct_id='$COOKIE->{ACCT}' or coas.acct_id='GEN')  and inv_txns.inv_id=$Inv_id order by inv_txns.itdate");
$ITs->execute;
$IT = $ITs->fetchall_arrayref({});
$ITs->finish;

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
        WRAPPER => 'header.tt',
});

print "Content-Type: text/html\n\n";
if ($Invoice->{"invstatuscode"} == 1) {		#   Draft
$Vars = {
        title => 'Accounts - Customers',
	cookie => $COOKIE,
        vats => $Vat,
	focus => 'desc',
	invoice => $Invoice,
	entries => $IT,
        javascript => '<script type="text/javascript" src="/js/add_lineitem.js"></script>
<script language="JavaScript">
var responseText = "";
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
      document.getElementById("invitems").value = document.getElementById("div_html").innerHTML;
      var submit_data = $(".newinvoice").serialize() + "&submit=" + action;
      $.post("/cgi-bin/fpa/save_invoice.pl",submit_data ,function(data) {
        if ( ! /^OK/.test(data)) {
          document.getElementById("dialog").innerHTML = data;
          $("#dialog").dialog("open");
        }
        else {
          var href = data.split("-");
          location.href = "/cgi-bin/fpa/" + href[1];
        }
      },"text");
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
function change_invtext(obj) {
  if (obj.value == "S") {
    $(".invtext").each( function() { this.innerHTML = "Invoice"; });
  }
  else {
    $(".invtext").each( function() { this.innerHTML = "Credit Note"; });
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
        var dg = document.getElementById("div_html").innerHTML.replace(/\+/gim,"%2B");
        var submit_data = $(".newinvoice").serialize() + "&invtotal=" + escape(document.getElementById("st").innerHTML) + "&invvat=" + escape(document.getElementById("vt").innerHTML) + "&invitems=" + escape(dg) + "&submit=" + action;
        $.post("/cgi-bin/fpa/save_invoice.pl",submit_data ,function(data) {
          if ( ! /^OK/.test(data)) {
            document.getElementById("dialog").innerHTML = data;
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
}
</script>'
};

	$tt->process('update_invoice.tt',$Vars);
}
else {		#  final
$Vars = {
        title => 'Accounts - Customers',
	cookie => $COOKIE,
	invoice => $Invoice,
	entries => $IT,
	focus => '',
        javascript => '<script language="JavaScript">
$(document).ready(function(){
  $("#i_invprintdate").datepicker();
  $("#invpayment").dialog({
    bgiframe: true,
    autoOpen: false,
    position: [200,100],
    height: 350,
    width: 400,
    modal: true,
    buttons: {
      "Record Payment": function() {
        if(validate_form("#pay2form")) {
          if ($("#i_txnmethod option:selected").text() == \'Refund\') {
            if (document.getElementById("i_txnamount").value == document.getElementById("i_amtowed").innerHTML) {
              $.post("/cgi-bin/fpa/receive_invoice_refund.pl",$("form#pay2form").serialize() ,function(data) {
              $(this).dialog("close");
              window.location.reload(true); },"text");
            }
            else {
              document.getElementById("dialog").innerHTML = "You cannot use the Refund option unless you are refunding the total owed.";
              $("#dialog").dialog("open");
            }
          }
          else {
            if (parseFloat(document.getElementById("i_txnamount").value) > parseFloat(document.getElementById("i_amtowed").innerHTML)) {
              if (confirm("Paid Amount greater than Owed Amount, balance will be held on Account")) {
                $.post("/cgi-bin/fpa/receive_invoice_payment.pl", $("#pay2form").serialize(),function(data) {
                if ( ! /^OK/.test(data)) {
                  document.getElementById("dialog").innerHTML = data;
                  $("#dialog").dialog("open");
                }
                window.location.reload(true);
                },"text");
                $(this).dialog("close");
              }
            }
            else {
              $.post("/cgi-bin/fpa/receive_invoice_payment.pl", $("form#pay2form").serialize(),function(data) {
                if ( ! /^OK/.test(data)) {
                  document.getElementById("dialog").innerHTML = data;
                  $("#dialog").dialog("open");
                }
                window.location.reload(true);
              },"text");
              $(this).dialog("close");
            }
          }
        }
      },
      Cancel: function() {
        $(this).dialog("close");
      }
    }
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
        if(validate_form("#fcancelreason")) {
          $.post("/cgi-bin/fpa/cancel_invoice.pl", $("form#fcancelreason").serialize(),function(data) {
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
      },
      Cancel: function() {
        $(this).dialog("close");
      }
    }
  });
  $("#writeoffreason").dialog({
    bgiframe: true,
    autoOpen: false,
    position: [200,100],
    height: 200,
    width: 400,
    modal: true,
    buttons: {
      "Write-off Invoice": function() {
        if(validate_form("#fcancelreason")) {
          $.post("/cgi-bin/fpa/writeoff_invoice.pl", $("form#fwriteoffreason").serialize(),function(data) {
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
      },
      Cancel: function() {
        $(this).dialog("close");
      }
    }
  });
});
function get_amt(amtinvid,amtinvno,amtamt) {
  document.getElementById("i_id").value = amtinvid;
  document.getElementById("i_amtinvno").innerHTML = amtinvno;
  document.getElementById("i_amtowed").innerHTML = parseFloat(amtamt).toFixed(2);
  document.getElementById("i_txnamount").value = parseFloat(amtamt).toFixed(2);
  document.getElementById("i_invdesc").value = "Invoice " + amtinvno;
//  document.getElementById("i_txnamount").focus();
  $("#invpayment").dialog("open");
}
function get_refund(amtinvid,amtinvno,amtamt) {
  document.getElementById("r_id").value = amtinvid;
  document.getElementById("r_amtinvno").innerHTML = amtinvno;
  document.getElementById("r_amtowed").innerHTML = parseFloat(amtamt).toFixed(2);
  document.getElementById("r_txnamount").value = parseFloat(amtamt).toFixed(2);
  document.getElementById("r_invdesc").value = "Refund against Invoice " + amtinvno;
//  document.getElementById("r_txnamount").focus();
  $("#refpayment").dialog("open");
}
function cancel_invoice(invid) {
  $("#cancelreason").dialog("open");
  document.getElementById("cancelmsg").focus();
}
function writeoff_invoice(invid) {
  $("#writeoffreason").dialog("open");
  document.getElementById("writeoffmsg").focus();
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
</script>'
};
	$tt->process('final_invoice.tt',$Vars);
}

$Invoices->finish;
$dbh->disconnect;
exit;

