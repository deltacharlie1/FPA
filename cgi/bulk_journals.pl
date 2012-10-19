#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to list invoices

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");
$Today = `date +%d-%b-%y`;
chomp($Today);

($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});

$COAs = $dbh->prepare("select coanominalcode,coadesc,coatype from coas where acct_id='$COOKIE->{ACCT}' order by coanominalcode");
$COAs->execute;
$COA = $COAs->fetchall_arrayref({});
$COAs->finish;

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
        WRAPPER => 'header.tt',
});

$Vars = {
	 ads => $Adverts,
        title => 'Journal Entries',
	cookie => $COOKIE,
	focus => 'adjstdesc',
	coas => $COA,
	today => $Today,
        javascript => '<style>
.mand2 { background-color:#f8e8c8; }
.hd { font-weight:bold;font-size:1.2em;padding-left:3px; }
.topb { border-top:1px solid #337040 !important; }
</style>
<script type="text/javascript">
$(document).ready(function() {
  $("#adjstdate").datepicker();
});

var ctrlacct = "";
var ctrlamt = "";
var item_rows = [];
var tbl;
var errfocus = "";
var current_row = -1;

function display_table() {

  var totdeb = 0;
  var totcred = 0;

  var item_table = "";

  var bkgd = ["odd","even"];
  var bk_ndx = 0;

  for (var i=0; i<item_rows.length; i++) {
    var debamt = item_rows[i][3];
    var credamt = item_rows[i][4];
    var topline = "";

    if (debamt=="0.00") { debamt="&nbsp;"; }
    if (credamt=="0.00") { credamt="&nbsp;"; }

    if (i>0) {
      topline = " class=\'topb\'";
    }

    item_table = item_table + "<tr  class=\'" + bkgd[bk_ndx % 2] + "\'>";
    item_table = item_table + "<td" + topline + ">" + item_rows[i][0] + "</td>";
    item_table = item_table + "<td" + topline + ">" + item_rows[i][1] + "</td>";
    item_table = item_table + "<td" + topline + ">" + item_rows[i][2] + "</td>";
    item_table = item_table + "<td" + topline + " style=\'text-align:right;\'>" + debamt + "</td>";
    item_table = item_table + "<td" + topline + " style=\'text-align:right;\'>" + credamt + "</td>";
    item_table = item_table + "<td" + topline + " style=\'text-align:center;\'><img src=\'/icons/inv_del.png\' title=\'Delete\' onclick=\"dlt(\'" + i + "\');\"/></td></tr>";
    
    for (var j=0; j<item_rows[i][5].length; j++) {
      bk_ndx = bk_ndx + 1;
      var subrow = item_rows[i][5][j];
      var debamt = subrow[1];
      var credamt = subrow[2];

      if (debamt=="0.00") { debamt="&nbsp;"; }
      if (credamt=="0.00") { credamt="&nbsp;"; }
      item_table = item_table + "<tr class=\'" + bkgd[bk_ndx % 2] + "\'>";
      item_table = item_table + "<td>&nbsp;</td><td>&nbsp;</td>";
      item_table = item_table + "<td>" + subrow[0] + "</td>";
      item_table = item_table + "<td style=\'text-align:right;\'>" + debamt + "</td>";
      item_table = item_table + "<td style=\'text-align:right;\'>" + credamt + "</td>";
      item_table = item_table + "<td>&nbsp;</td></tr>";
      totdeb = totdeb + (subrow[1] * 1);   
      totcred = totcred + (subrow[2] * 1);   
    }
    totdeb = totdeb + (item_rows[i][3] * 1);   
    totcred = totcred + (item_rows[i][4] * 1);   

    bk_ndx = bk_ndx + 1;
  }
  $("#new").html(item_table);
  $("#totdeb").html(totdeb.toFixed(2));
  $("#totcred").html(totcred.toFixed(2));
  var bal = Math.abs((totdeb - totcred)).toFixed(2);
  $("#bal").html(bal);
  document.getElementById("data").value = item_table;
}

function add_entry() {
  var errs = "";
  errfocus = "";
  if (ctrlacct == "") {
    if ($("#adjstdate").val()=="") {
      errs = errs + "<li>No Date</li>\\n";
      if (errfocus == "") {
        errfocus = "adjstdate";
      }
    }
    if ($("#adjstdesc").val()=="") {
      errs = errs + "<li> No Description</li>\\n";
      if (errfocus == "") {
        errfocus = "adjstdesc";
      }
    }
    if ($("#adjstacct").val()=="") {
      errs = errs + "<li>No Account Selected</li>\\n";
      if (errfocus == "") {
        errfocus = "adjstacct";
      }
    }
    if ($("#adjstdebamt").val()=="" && $("#adjstcredamt").val()=="") {
      errs = errs + "<li>Both Debit and Credit fields are empty</li>\\n";
      if (errfocus == "") {
        errfocus = "adjstdebamt";
      }
    }
    if ($("#adjstdebamt").val()!="" && $("#adjstcredamt").val()!="") {
      errs = errs + "<li>You cannot enter both a Debit and Credit amount for a single Nominal Account</li>\\n";
      $("#adjstdebamt").val("");
      $("#adjstcredamt").val("");
      if (errfocus == "") {
        errfocus = "adjstdebamt";
      }
    }
    if (errs != "") {
      errs = "You have the following errors:-<ul>" + errs + "</ul>";
      $("#dialog").html(errs);
      $("#dialog").dialog("open");
    }
    else {

      current_row = current_row + 1;

      var item_row;
      var subrows = [];
      var debamt = ($("#adjstdebamt").val() * 1).toFixed(2);
      var credamt = ($("#adjstcredamt").val() * 1).toFixed(2);
      item_row = [$("#adjstdate").val(),$("#adjstdesc").val(),$("#adjstacct option:selected").text(),debamt,credamt,subrows];

      item_rows.push(item_row);
      display_table();

      ctrlacct = $("#adjstacct").val();
      $("#adjstdate").datepicker("disable");
      $("#adjstdesc").attr("readonly",true);
      $("#adjstacct").val(-1);
      if ($("#adjstdebamt").val()!="") {
        $("#adjstdebamt").parent().css("visibility","hidden");
        $("#adjstcredamt").val($("#adjstdebamt").val());
        $("#adjstdebamt").val("");
        ctrlamt = "adjstcredamt";
      }
      else {
        $("#adjstdebamt").val($("#adjstcredamt").val());
        $("#adjstcredamt").val("");
        $("#adjstcredamt").parent().css("visibility","hidden");
        ctrlamt = "adjstdebamt";
      }
      $("#"+ctrlamt).focus();
    }
  }
  else {
    if ($("#adjstacct").val()=="") {
      errs = errs + "<li>No Account Selected</li>\\n";
      if (errfocus == "") {
        errfocus = "adjstacct";
      }
    }
    if ( /cred/i.test(ctrlacct) && $("#adjstdebamt").val()=="") {
      errs = errs + "<li>No Debit Amount</li>\\n";
      if (errfocus == "") {
        errfocus = "adjstdebamt";
      }
    }
    if ( /deb/i.test(ctrlacct) && $("#adjstcredamt").val()=="") {
      errs = errs + "<li>No Credit Amount</li>\\n";
      if (errfocus == "") {
        errfocus = "adjstdebamt";
      }
    }
    var bal = ($("#bal").text() * 1).toFixed(2);
    var amt = ($("#"+ctrlamt).val() * 1).toFixed(2);
    if (bal - amt < 0) {
      errs = errs + "<li>Entered Amount would take Balance to less than zero</li>\\n";
      if (errfocus == "") {
        $("#"+ctrlamt).val("");
        errfocus = ctrlamt;
      }
    }
    if (errs != "") {
      errs = "You have the following errors:-<ul>" + errs + "</ul>";
      $("#dialog").html(errs);
      $("#dialog").dialog("open");
    }
    else {
      var debamt = ($("#adjstdebamt").val() * 1).toFixed(2);
      var credamt = ($("#adjstcredamt").val() * 1).toFixed(2);
      var subrow;
      subrow = [$("#adjstacct option:selected").text(),debamt,credamt];

      item_rows[current_row][5].push(subrow); 
      display_table();
      var totdeb = ($("#totdeb").html() * 1);
      var totcred = ($("#totcred").html() * 1);
      var bal = Math.abs((totdeb - totcred)).toFixed(2);
      if (bal > 0) {
        $("#"+ctrlamt).val(bal);
      }
      else {
        $("#"+ctrlamt).val("");
      }
      $("#adjstacct").val(-1);
      $("#"+ctrlamt).focus();

      if ($("#bal").html()=="0.00") {
        ctrlacct = "";
        ctrlamt="";
        $("#totdeb").html("0.00");
        $("#totcred").html("0.00");
        $("#adjstdate").datepicker("enable");
        $("#adjstdesc").attr("readonly",false);
        $("#adjstcredamt").parent().css("visibility","visible");
        $("#adjstdebamt").parent().css("visibility","visible");
        $("#adjstdesc").val("");
        $("#adjstdesc").focus();
      }
    }
  }
}
function dlt(row) {
  item_rows.splice(row,1);
  current_row = current_row - 1;
  ctrlacct = "";
  ctrlamt="";
  $("#totdeb").html("0.00");
  $("#totcred").html("0.00");
  $("#adjstdate").datepicker("enable");
  $("#adjstdesc").attr("readonly",false);
  $("#adjstcredamt").parent().css("visibility","visible");
  $("#adjstdebamt").parent().css("visibility","visible");
  $("#adjstcredamt").val("");
  $("#adjstdebamt").val("");
  $("#adjstdesc").val("");
  $("#adjstdesc").focus();
  display_table();
}
function check_data() {
  if (document.getElementById("data").value.length > 1) {
    if ($("#bal").html() == "0.00" || confirm("Debits & Credits do not Balance!  Are you sure you want to continue?")) {
      return true;
    }
    else {
      return false;
    }
  }
  else {
    $("#dialog").html("You have not entered any journal entries!");
    errfocus = "adjstdesc";
    $("#dialog").dialog("open");
    return false;
  }
}
</script>',
};

print "Content-Type: text/html\n\n";
$tt->process('bulk_journals.tt',$Vars);

$dbh->disconnect;
exit;

