var errfocus = "";
var ajax_return = "";
$(document).ready(function(){
  $(".mandatory").before("<span style='font-size:20px;font-weight:bold;color:red;padding:0 6px 0 0;'>*<\/span>");
  $("#searchimg").click(function() {
    switch(document.getElementById('dfg').title) {
      case 'Customers':
        document.getElementById('dfg').title = "Suppliers";
        document.getElementById('dfg').innerHTML = "Search Suppliers";
        $("#searchcus").autocomplete("option","minLength",1);
        break;
      case 'Suppliers':
        document.getElementById('dfg').title = "Sales Invoices";
        document.getElementById('dfg').innerHTML = "Search Sales Invoices";
        $("#searchcus").autocomplete("option","minLength",3);
        break;
      case 'Sales Invoices':
        document.getElementById('dfg').title = "Purchase Invoices";
        document.getElementById('dfg').innerHTML = "Search Purchase Invoices";
        $("#searchcus").autocomplete("option","minLength",3);
        break;
      default:
        document.getElementById('dfg').title = "Customers";
        document.getElementById('dfg').innerHTML = "Search Customers";
        $("#searchcus").autocomplete("option","minLength",1);
        break;
    }
  });
  $("#searchcus").autocomplete({
    minLength: 3,
    source: function (request,response) {
      request.type = document.getElementById("dfg").title;
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
      switch(document.getElementById('dfg').title) {
        case 'Customers':
          location.href="/cgi-bin/fpa/list_customer_invoices.pl?" + ui.item.id;
          break;
        case 'Suppliers':
          location.href="/cgi-bin/fpa/list_supplier_purchases.pl?" + ui.item.id;
          break;
        case 'Sales Invoices':
          location.href="/cgi-bin/fpa/update_invoice.pl?" + ui.item.id;
          break;
        case 'Purchase Invoices':
          location.href="/cgi-bin/fpa/update_purchase.pl?" + ui.item.id;
          break;
        default:
          location.href="/cgi-bin/fpa/list_customer_invoices.pl?" + ui.item.id;
          break;
      }
    }
  });
  $.datepicker.setDefaults({showOn: "button", buttonImage: "/images/calendaricon.gif", buttonImageOnly: true, buttonText: "", dateFormat: "dd-M-y", duration: "", changeYear: true,changeMonth: true});
  $("#rec_cus_id").autocomplete({
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
      document.getElementById("rec_amtcusid").value = ui.item.id;
      $("#rec_invcoa").val(ui.item.coa);
      $("#rec_vatrate").val(ui.item.vatrate);
      $("#rec_txnamount").focus();
    }
  });
  $("#rec_invprintdate").datepicker();
  $("#pay_cus_id").autocomplete({
    minLength: 0,
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
      document.getElementById("pay_amtcusid").value = ui.item.id;
      $("#pay_invcoa").val(ui.item.coa);
      $("#pay_vatrate").val(ui.item.vatrate);
      $("#pay_txnamount").focus();
    }
  });
  $("#pay_invprintdate").datepicker();
  $("#remstartdate").datepicker();
  $("#remenddate").datepicker();
  $("#dialog").dialog({
    bgiframe: true,
    height: 200,
    autoOpen: false,
    position: [200,100],
    modal: true,
    buttons: { "Ok": function() { $(this).dialog("close");setfocus(); } }
  });
  $("#vcomments").dialog({
    bgiframe: true,
    height: 200,
    autoOpen: false,
    position: [200,100],
    modal: true
  });
  $("#vcomment").dialog({
    bgiframe: true,
    autoOpen: false,
    position: [200,100],
    height: 350,
    width: 400,
    modal: true,
    buttons: {
      "Save": function() {
        if (document.getElementById("comtext").value.length > 0) {
          $.post("/cgi-bin/fpa/add_comment.pl", { comtext: document.getElementById("comtext").value, comgrade: document.getElementById("comgrade").value },function(data) {
            document.getElementById("dialog").title = "";
            document.getElementById("dialog").innerHTML = data;
            errfocus = "comtext";
            $("#dialog").dialog("open");
            document.getElementById("comtext").value = "";
          },"text");
          $(this).dialog("close");
       }
       else {
          document.getElementById("dialog").innerHTML = "You have not entered any comment";
          errfocus = "comtext";
          $("#dialog").dialog("open");
       }
      },
      Cancel: function() {
        $(this).dialog("close");
      }
    }
  });
  $("#vreminders").dialog({
    bgiframe: true,
    height: 200,
    autoOpen: false,
    position: [200,100],
    modal: true
  });
  $("#vreminder").dialog({
    bgiframe: true,
    autoOpen: false,
    position: [200,100],
    height: 350,
    width: 400,
    modal: true,
    buttons: {
      "Save": function() {
        if (document.getElementById("remtext").value.length > 0) {
          $.post("/cgi-bin/fpa/add_reminder.pl", { remtext: document.getElementById("remtext").value, remgrade: document.getElementById("remgrade").value, remstartdate: document.getElementById("remstartdate").value, remenddate: document.getElementById("remenddate").value } ,function(data) {
            document.getElementById("dialog").title = "";
            document.getElementById("dialog").innerHTML = data;
            errfocus = "remtext";
            $("#dialog").dialog("open");
            document.getElementById("remtext").value = "";
            document.getElementById("remstartdate").value = "";
            document.getElementById("remenddate").value = "";
          },"text");
          $(this).dialog("close");
       }
       else {
          document.getElementById("dialog").innerHTML = "You have not entered any message";
          errfocus = "remtext";
          $("#dialog").dialog("open");
       }
      },
      Cancel: function() {
        $(this).dialog("close");
      }
    }
  });
  $("#receipt2").dialog({
    bgiframe: true,
    autoOpen: false,
    position: [200,100],
    height: 420,
    width: 500,
    modal: true,
    buttons: {
      "Record Receipt": function() {
        if (validate_form("#recform2")) {
          document.getElementById("rec_invcusname").value = document.getElementById("rec_cus_id").value;
          $.post("/cgi-bin/fpa/process_txn.pl", $("form#recform2").serialize(),function(data) {
            if ( ! /^OK/.test(data)) {
              alert(data);
            }
            window.location.reload(true);
          },"text");
          $(this).dialog("close");
        }
      },
      Cancel: function() {
        $(".error").removeClass("error");
        $("#recform2")[0].reset();
        $(this).dialog("close");
      }
    }
  });
  $("#payment2").dialog({
    bgiframe: true,
    autoOpen: false,
    position: [200,100],
    height: 475,
    width: 500,
    modal: true,
    buttons: {
      "Record Payment": function() {
        if (validate_form("#payform2")) {
          document.getElementById("pay_invcusname").value = document.getElementById("pay_cus_id").value;
          $.ajax({ 
            url      : "/cgi-bin/fpa/process_txn.pl", 
            data     : $("form#payform2").serialize(), 
            async    : false, 
            success  : function(data) {
              ajax_return = data;
              if ( ! /^OK/.test(data)) {
                alert(data);
              }
            }
          });
          if (document.getElementById("pifileQueue") != null) {
            var href = ajax_return.split("-");
            var c_name = "fpa-cookie";
            var cookie = "";
            if (document.getElementById("pifileQueue").innerHTML.length > 0 && parseInt(href[1]) > 0) {
              if (document.cookie.length>0) {
                c_start=document.cookie.indexOf(c_name + "=");
                if (c_start!=-1) {
                  c_start=c_start + c_name.length+1;
                  c_end=document.cookie.indexOf(";",c_start);
                  if (c_end==-1) c_end=document.cookie.length;
                  cookie = unescape(document.cookie.substring(c_start,c_end));
                }
              }
              $("#pifile").uploadifySettings("scriptData",{"cookie" : cookie, "doc_type" : "INV", "doc_rec" : href[1] },true );
              $("#pifile").uploadifyUpload();
            }
          }
          window.location.reload(true);
          $(this).dialog("close");
        }
      },
      Cancel: function() {
        $(".error").removeClass("error");
        $("#payform2")[0].reset();
        $(this).dialog("close");
      }
    }
  });

//  $("#wrapper").css("height",$(document).height() > 900 ? $(document).height() + 20 : 900);
//  $("#body").css("height",$("#wrapper").height() - 260);
});
function print_display() {
  if ($(".main").length) {
    $(".main").print();
  }
  else {
    window.print();
  }
// alert(document.URL);
}

function validate_form(form) {
  var errs = "";
  $(".error").removeClass("error");
  $(":input.mandatory",form).each(function() {
    if ($(this).is(".mandatory") && $(this).val() == "") {
      errs = errs + "<li>Empty " + this.title + "<\/li>";
      $(this).parent().addClass("error");
      if (errfocus == "") {
        errfocus = this.id;
      }
    }
    else {
      if ($(this).is(".currency") && $(this).val() != "" && ! /^-?\d+\.?\d?\d?$/.test($(this).val())) {
        errs = errs + "<li>" + this.title + "  must contain a valid currency amount (n.nn)<\/li>";
        $(this).parent().addClass("error");
        if (errfocus == "") {
          errfocus = this.id;
        }
      }
    }
  });
  if (errs.length > 0) {
    errs = "You have the following error(s):-<ol>" + errs + "<\/ol>Please correct them before re-submitting";
    document.getElementById("dialog").innerHTML = errs;
    $("#dialog").dialog("open");
    return false;
  }
  else {
    return true;
  }
}
function setfocus() {
  try {eval("document.getElementById(\'" + errfocus + "\').focus();");}
  catch(e) {}
}
function check_currency(obj) {
  if (obj.value.length > 0) {
    if (! /^-?\d+\.?\d?\d?$/.test(obj.value)) {
      document.getElementById("dialog").innerHTML = obj.value + "is an invalid currency format, please correct";
      $("#dialog").dialog("open");
      obj.value="";
      errfocus = obj.id;
    }
  }
}
function calc_vat(obj) {
  if (/^pay/.test(obj.id)) {
    if (/^-?\d+\.?\d?\d?/.test(document.getElementById("pay_txnamount").value)) {
      var totamt = parseFloat(document.getElementById("pay_txnamount").value);
      var vat = parseFloat(document.getElementById("pay_vatrate").value);
      var vatdiv = vat + 1;
      var vatvalue = totamt * vat / vatdiv;
      document.getElementById("pay_invvat").value = vatvalue.toFixed(2);
      var netamt = totamt - vatvalue;
      document.getElementById("pay_netamt").innerHTML = "(Net = " + netamt.toFixed(2) + ")";
    }
    else {
      document.getElementById("pay_invvat").value = "";
      document.getElementById("pay_netamt").innerHTML = "";
    }
  }
  else {
    if (/^-?\d+\.?\d?\d?/.test(document.getElementById("rec_txnamount").value)) {
      var totamt = parseFloat(document.getElementById("rec_txnamount").value);
      var vat = parseFloat(document.getElementById("rec_vatrate").value);
      var vatdiv = vat + 1;
      var vatvalue = totamt * vat / vatdiv;
      document.getElementById("rec_invvat").value = vatvalue.toFixed(2);
      var netamt = totamt - vatvalue;
      document.getElementById("rec_netamt").innerHTML = "(Net = " + netamt.toFixed(2) + ")";
    }
    else {
      document.getElementById("rec_invvat").value = "";
      document.getElementById("rec_netamt").innerHTML = "";
    }
  }
}
function display_form(io) {
  $(".error").removeClass("error");
  if (io == "I") {
    $("#rec_netamt").html("");
    $("#receipt2").dialog("open");
    document.getElementById("rec_cus_id").focus();
  }
  else {
    $("#pay_netamt").html("");
    $("#payment2").dialog("open");
    if (io == "E") {
      $(".notexpenses").hide();
      $("#pay_cus_id").removeClass("mandatory");
      document.getElementById("pay_txnamount").focus();
      document.getElementById("pay_invtype").value = "E";
      document.getElementById("pay_amtcusid").value = document.getElementById("expid").value;
    }
    else {
      $(".notexpenses").show();
      $("#pay_cus_id").addClass("mandatory");
      document.getElementById("pay_invtype").value = "P";
      document.getElementById("pay_cus_id").focus();
    }
  }
}
function view_comments() {
  $.ajax({ url: "/cgi-bin/fpa/view_comments.pl", cache: false, success: function(data) {
    document.getElementById("vcomments").innerHTML = data;
    $("#vcomments").dialog("open");
  }});
}
function view_reminders() {
  $.ajax({ url: "/cgi-bin/fpa/view_reminders.pl", cache: false, success: function(data) {
    document.getElementById("vreminders").innerHTML = data;
    $("#vreminders").dialog("open");
  }});
}
function delete_reminder(id) {
  $.get("/cgi-bin/fpa/delete_reminder.pl?" + id,function(data) {
    window.location.reload(true);
  });
}
