#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to reconcile an account

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

$Acctype = $ENV{QUERY_STRING};

use DBI;
my $dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");

$Accts = $dbh->prepare("select accounts.id,accounts.acctype,accname,accacctno,stastmtno,staclosebal,date_format(staclosedate,'%d-%b-%y') as staclosedate from accounts left join statements on (accounts.id=acc_id) where accounts.acct_id='$COOKIE->{ACCT}' and acctype='$Acctype' order by statements.id desc limit 1");
$Accts->execute;
$Acct = $Accts->fetchrow_hashref;
$Accts->finish;

$TSs = $dbh->prepare("select f1,f2,f3 from tempstacks where acct_id='$COOKIE->{ACCT}' and caller='reconciliation'");
$TSs->execute;
$TS = $TSs->fetchrow_hashref;
$TSs->finish;

$Txns = $dbh->prepare("select id,txntxntype,date_format(txndate,'%d-%b-%y') as tdate,concat(txncusname,' (',txnremarks,')') as txncusname,txnamount,txnselected from transactions where txnselected<>'F' and txnmethod='$Acctype' and acct_id='$COOKIE->{ACCT}' order by txndate");
$Txns->execute;

#  Check to see if there are any Filed VAT returns awaiting reconciliation

$Vats = $dbh->prepare("select id,perquarter,perbox5 from vatreturns where acct_id='$COOKIE->{ACCT}' and perstatus='Filed' order by perstartdate limit 1");
$Vats->execute;
if ($Vats->rows > 0) {
	$Vat = $Vats->fetchrow_hashref;
  	$Vatdate = "\$(\"#vatdte\").datepicker({ maxDate: new Date() });";
}
$Vats->finish;

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
        WRAPPER => 'header.tt',
});

$Vars = {
        title => 'Accounts - Reconciliations',
	cookie => $COOKIE,
	acct => $Acct,
	vat => $Vat,
	stack => $TS,
	entries => $Txns->fetchall_arrayref({}),
	javascript => '<script type="text/javascript">
var errfocus;
$(document).ready(function() {
  $("#changedate").dialog({
    bgiframe: true,
    autoOpen: false,
    position: [200,100],
    height: 200,
    width: 300,
    modal: true,
    buttons: {
      "Change Date": function() {
        $.post("/cgi-bin/fpa/change_txn_date.pl", $("#fchangedate").serialize(),function(data) {
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
  $("#thisintdate").datepicker({ maxDate: new Date() });
  $("#thiscfdate").datepicker({ maxDate: new Date() });
  $("#thischdate").datepicker({ maxDate: new Date() });
'.$Vatdate.'
  $("#newdate").datepicker({ maxDate: new Date() });
  var ichkd= 0;

  $(".txnchk").each(
    function() {
      if ($(this).is(":checked")) {
        ichkd = ichkd + parseFloat($(this).val());
      }
    }
  );
  document.getElementById("chkditems").innerHTML = ichkd.toFixed(2);

  var ibal = 0;
  var ibf = 0;
  var icf = 0;

  ibf = document.getElementById("thisbf").innerHTML;
  if (document.getElementById("thiscf").value.length > 0) {
    icf = document.getElementById("thiscf").value;
  }

  ibal = parseFloat(icf) - parseFloat(ibf);

  document.getElementById("staact").innerHTML = ibal.toFixed(2);
  document.getElementById("txndiff").innerHTML = (ibal - parseFloat(document.getElementById("chkditems").innerHTML)).toFixed(2);
  if (document.getElementById("txndiff").innerHTML == "-0.00") {
    document.getElementById("txndiff").innerHTML = "0.00";
  }
});
function showResponse(responseText, statusText) {
  window.location.reload(true);
}

function sorttable() {
  var cls = new Array();
  cls[0] = "even";
  cls[1] = "odd";
  var cls_ndx = 0;

  var body = document.getElementById("sorttable");
  var noRows = body.rows.length;
  for (var i=noRows - 1;i>=0;i--) {
    cls_ndx++;
    var El = body.removeChild(body.rows[i]);
    El.className = cls[cls_ndx%2];
    body.appendChild(El);
  }
}
function check_bals() {
  var errs = "";
  if (! /^-?\d+\.?\d?\d?/.test(document.getElementById("thiscf").value)) {
    errs = errs + "<li>You must enter a Balance Brought Forward in the correct format<\/li>\n";
  }
  if (errs.length > 0) {
    document.getElementById("dialog").innerHTML = "You have the following errors<ol>" + errs + "<\/ol>Please correct them";
    $("#dialog").dialog("open");
  }
  else {
    var ibal = 0;
    var ibf = 0;
    var icf = 0;

    ibf = document.getElementById("thisbf").innerHTML;
    if (document.getElementById("thiscf").value.length > 0) {
      icf = document.getElementById("thiscf").value;
    }

    ibal = parseFloat(icf) - parseFloat(ibf);

    document.getElementById("staact").innerHTML = ibal.toFixed(2);
    document.getElementById("txndiff").innerHTML = (ibal - parseFloat(document.getElementById("chkditems").innerHTML)).toFixed(2);

    if (/0\.00/.test(document.getElementById("txndiff").innerHTML)) {
      document.getElementById("txndiff").innerHTML = "0.00";   //  get rid of any potential minus sign
    }
    $.get("/cgi-bin/fpa/reconcileupd1.pl", { f1: document.getElementById("thisno").value, f2: document.getElementById("thiscf").value, f3: document.getElementById("thiscfdate").value });
   }
}
function updstack() {
  var errs = "";
  if (document.getElementById("thisno").value.length > 0 && ! /^\d+/.test(document.getElementById("thisno").value)) {
    errs = errs + "<li>Invalid Bank Statement Format<\/li>\n";
    errfocus = "thisno";
  }
  if (errs.length > 0) {
    document.getElementById("dialog").innerHTML = "You have entered an invalid format:-<ol>" + errs + "<\/ol>Please correct and re-submit\n";
    $("#dialog").dialog("open");
  }
  else {
    $.get("/cgi-bin/fpa/reconcileupd1.pl", { f1: document.getElementById("thisno").value, f2: document.getElementById("thiscf").value, f3: document.getElementById("thiscfdate").value });
  }
}
function check_txn(obj) {
  if ($("#" + obj.id).is(":checked")) {
    $.get("/cgi-bin/fpa/reconcileupd2.pl", { state: "P", txnid: obj.id });
  }
  else {
    $.get("/cgi-bin/fpa/reconcileupd2.pl", { state: "", txnid: obj.id });
  }
  var itot = 0;
  $(".txnchk").each(
    function() {
      if ($(this).is(":checked")) {
        itot = itot + parseFloat($(this).val());
      }
    }
  );
  document.getElementById("chkditems").innerHTML = itot.toFixed(2);
}
function do_vatpayment () {
  $.post("/cgi-bin/fpa/vat_payment.pl", $("#form1").serialize(),function(data) {
    window.location.reload(true);
  },"text");
}
function do_bankpayment() {
  var errs = "";
  if (document.getElementById("thisint").value.length > 0 && ! /^\-?\d+\.?\d?\d?$/.test(document.getElementById("thisint").value)) {
    errs = errs + "<li>Invalid Bank Interest Amount<\/li>\n";
    errfocus = "thisint";
  }
  if (document.getElementById("thisch").value.length > 0 && ! /^\-?\d+\.?\d?\d?$/.test(document.getElementById("thisch").value)) {
    errs = errs + "<li>Invalid Bank Charges Amount<\/li>\n";
    errfocus = "thisch";
  }
  if (errs.length > 0) {
    document.getElementById("dialog").innerHTML = "You have an invalid currency format:-<ol>" + errs + "<\/ol>Please correct and re-submit\n";
    $("#dialog").dialog("open");
  }
  else {
    $.post("/cgi-bin/fpa/bank_payment.pl", $("#form1").serialize(),function(data) {
      window.location.reload(true);
    },"text");
  }
}
function validate() {
  if (validate_form("form1")) {
    if (document.getElementById("staact").innerHTML != document.getElementById("chkditems").innerHTML) {
      document.getElementById("dialog").innerHTML = "You have the following errors:-<ol><li>The value of checked items does not agree with your bank statement<\/li><\/ol> please correct";
      $("#dialog").dialog("open");
      return false;
    }
    else {
      $.post("/cgi-bin/fpa/reconcile2.pl",$("form#form1").serialize(),function(data) {
        if (/OK/i.test(data)) {
          var href = data.split("-");
          location.href = "/cgi-bin/fpa/" + href[1];
        }
        else {
          document.getElementById("dialog").innerHTML = data;
          $("#dialog").dialog("open");
          return false;
        }
      });
    }
  }
}
function change_date(obj,id,olddate) {
  $(obj).addClass("error");
  document.getElementById("cd_id").value = id;
  document.getElementById("newdate").value = olddate;
  $("#changedate").dialog("open");
}
</script>'
};

print "Content-Type: text/html\n\n";
$tt->process('reconcile.tt',$Vars);

$Txns->finish;
$dbh->disconnect;
exit;

