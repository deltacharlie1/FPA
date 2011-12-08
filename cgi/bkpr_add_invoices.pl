#!/usr/bin/perl

$ACCESS_LEVEL = 5;

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

$Customers = $dbh->prepare("select id,cusname from customers where iacct_id='$COOKIE->{ACCT}' order by cusname;");
$Customers->execute;

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
        WRAPPER => 'header.tt',
});

$Vars = {
        title => 'Add Invoicies',
	cookie => $COOKIE,
	focus => 'customer',
	customers => $Customers->fetchall_arrayref({}),
        javascript => '<script type="text/javascript">
var item_rows = [];
var tbl;
$(document).ready(function () {
  $("#invdate").datepicker();
});

function display_table() {
  var item_table = "";
  var vatqend = [];
  vatqend[1] = "Jan/Apr/Jul/Oct";
  vatqend[2] = "Feb/May/Aug/Nov";
  vatqend[3] = "Mar/Jun/Sep/Dec";

  var bkgd = ["odd","even"];

  for (var i=0; i<item_rows.length; i++) {
    item_table = item_table + "<tr class=\'" + bkgd[i % 2] + "\'>";
    for (var j=0;j<7; j++) {
      if (item_rows[i][j] == undefined) {
        item_table = item_table + "<td>&nbsp;</td>";
      }
      else {
        if (j == 5 && item_rows[i][j] != "") {
          item_table = item_table + "<td>" + vatqend[item_rows[i][j]] + "</td>";
        }
        else {
          if (j == 3 || j == 4 || j == 6) {
            item_table = item_table + "<td style=\'text-align:center;\'>" + item_rows[i][j] + "</td>";
          }
          else {
            item_table = item_table + "<td>" + item_rows[i][j] + "</td>";
          }
        }
      }
    }
    item_table = item_table + "<td style=\'text-align:center;\'><input type=\'button\' value=\'Amd\' onclick=\"amd(\'" + i + "\');\"/>&nbsp;<input type=\'button\' value=\'Del\' onclick=\"dlt(\'" + i + "\');\"/></td>\\n</tr>";
  }
  document.getElementById("new").innerHTML = item_table;
  document.getElementById("data").value = item_table;
}

function add_company() {
  var errs;
  if (validate_form("#form1")) {
    var item_row;
    item_row = [document.getElementById("company").value,document.getElementById("client").value,document.getElementById("email").value,document.getElementById("yearend").value,document.getElementById("vatscheme").value,document.getElementById("vatend").value,$("input:radio[name=cis]:checked").val()];

    item_rows.push(item_row);
    display_table();

    document.getElementById("company").value = "";
    document.getElementById("client").value = "";
    document.getElementById("email").value = "";
    document.getElementById("yearend").value = "";
    document.getElementById("vatscheme").value = "N";
    document.getElementById("vatend").value = "";
    $("#cisN").attr("checked",true);
  }
}

function amd(row) {
  $("#company").val(item_rows[row][0]);
  $("#client").val(item_rows[row][1]);
  $("#email").val(item_rows[row][2]);
  $("#yearend").val(item_rows[row][3]);
  $("#vatscheme").val(item_rows[row][4]);
  $("#vatend").val(item_rows[row][5]);
  if (item_rows[row][6] == "Y") {
    $("#cisY").attr("checked",true);
  }
  else {
    $("#cisY").attr("checked",false);
  }

  dlt(row);
}
function dlt(row) {
  item_rows.splice(row,1);
  display_table();
}
function check_data() {
  if (document.getElementById("data").value.length > 1) {
    return true;
  }
  else {
    document.getElementById("dialog").innerHTML = "You have not entered any company details!";
    errfocus = "company";
    $("#dialog").dialog("open");
    return false;
  }
}
</script>',
};

print "Content-Type: text/html\n\n";
$tt->process('bkpr_add_invoices.tt',$Vars);

$Companies->finish;
$dbh->disconnect;
exit;

