#!/usr/bin/perl

$ACCESS_LEVEL = 4;

#  script to bulk add invoices

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");
unless ($COOKIE->{NO_ADS}) {
	require "/usr/local/git/fpa/cgi/display_adverts.ph";
	&display_adverts();
}

($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});

$Coas = $dbh->prepare("select coas.coanominalcode,coas.coadesc,concat(coas.coagroup,' - ',a.coadesc) as coagrp,coas.coatype,coas.coagroup,coas.coareport,'existing' as status from coas left join coas a on (coas.coagroup=a.coanominalcode and coas.acct_id=a.acct_id) where coas.acct_id='$COOKIE->{ACCT}' and coas.coagroup in ('1000','1500','3100','4300','5000','6000','7000') order by coas.coanominalcode");
$Coas->execute;

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
        WRAPPER => 'header.tt',
});

$Vars = {
	 ads => $Adverts,
        title => 'Add Nominal Codes',
	cookie => $COOKIE,
	focus => 'coadesc',
	coas => $Coas->fetchall_arrayref({}),
        javascript => '<style>
.mand2 { background-color:#f8e8c8; }
</style>
<script type="text/javascript">
var item_rows = [];
var tbl;
var nominals = new Array();
nominals["1000"] = "1000 - Fixed Assets";
nominals["1500"] = "1000 - Current Assets";
nominals["3100"] = "3100 - Capital Account";
nominals["4300"] = "4300 - Other Income";
nominals["5000"] = "5000 - Cost of Sales";
nominals["6000"] = "6000 - Other Expenses";
nominals["7000"] = "7000 - Fixed Overheads";
var nomtypes = new Array();
nomtypes["1000"] = "Fixed Assets";
nomtypes["1500"] = "Current Assets";
nomtypes["3100"] = "Capital";
nomtypes["4300"] = "Income";
nomtypes["5000"] = "Expenses";
nomtypes["6000"] = "Expenses";
nomtypes["7000"] = "Expenses";

$(document).ready(function () {
  init_rows();
});
function init_rows() {
  tbl = document.getElementById("new");
  for (var i=1; i<tbl.rows.length; i++) {
    var item_row = [];
    for (var j=0; j<tbl.rows[i].cells.length; j++) {
        item_row[j] = tbl.rows[i].cells[j].innerHTML;
    }
    item_rows.push(item_row);
  }
}
function validate_nominal() {
  var errs = "";
  $(".mand2").each(function() {
    if (this.value.length < 1) { errs = errs + "<li>Empty " + this.title + "</li>"; }
  });
  if (errs.length > 0) {
    errfocus = "coadesc";
    $("#dialog").html("You have the following errors<ol>" + errs + "</ol>");
    $("#dialog").dialog("open");
  }
  else {
    add_nominal();
  }
}
function display_table() {
  var item_table = "";
  var bkgd = ["odd","even"];

  for (var i=0; i<item_rows.length; i++) {
    item_table = item_table + "<tr class=\'" + bkgd[i % 2] + "\'>";
    for (var j=0;j<7; j++) {
      if (j<5) {
        item_table = item_table + "<td>" + item_rows[i][j] + "</td>";
      }
      else {
        item_table = item_table + "<td style=\'display:none;\'>" + item_rows[i][j] + "</td>";
      }
    }
    if (item_rows[i][4]=="new") {
      item_table = item_table + "<td style=\'text-align:center;\'><input type=\'button\' value=\'Del\' onclick=\"dlt(\'" + i + "\');\"/></td>\\n</tr>";
    }
    else {
      item_table = item_table + "<td>&nbsp;</td>\\n</tr>";
    }
  }
  $("#new").html(item_table);
  document.getElementById("nom_data").value = item_table;
  document.getElementById("coadesc").focus();
}

function add_nominal() {
  var item_row;
  var reptype = "";
  if ($("#nom_nomcode").val() < 4000) {
    reptype="Balance Sheet";
  }
  else {
    reptype="P & L";
  }
  item_row = ["&nbsp;",document.getElementById("coadesc").value,nominals[document.getElementById("nom_nomcode").value],nomtypes[document.getElementById("nom_nomcode").value],"new",document.getElementById("nom_nomcode").value,reptype];

  item_rows.push(item_row);
  display_table();
  document.getElementById("coadesc").value = "";
}
function dlt(row) {
  item_rows.splice(row,1);
  display_table();
}
function check_data() {
  if (document.getElementById("nom_data").value.length > 1) {
    return true;
  }
  else {
    $("#dialog").html("You have not entered any accounts!");
    errfocus = "coadesc";
    $("#dialog").dialog("open");
    return false;
  }
}
</script>'
};

print "Content-Type: text/html\n\n";
$tt->process('add_nominals.tt',$Vars);

$Coas->finish;
$dbh->disconnect;
exit;

