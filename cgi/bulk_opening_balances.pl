#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to bulk add invoices

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");
unless ($COOKIE->{NO_ADS}) {
	require "/usr/local/git/fpa/cgi/display_adverts.ph";
	&display_adverts();
}

$Coas = $dbh->prepare("select coabalance from coas where acct_id='$COOKIE->{ACCT}' and coanominalcode='3100'");
$Coas->execute;
$Coa = $Coas->fetchrow_hashref;
$Coas->finish;

#  See if we have any statements (in which case we cannot do opening balances for those bank accounts)

$Stmts = $dbh->prepare("select count(acc_id) as cnt,acctype,accshort from accounts left join statements on (accounts.id=acc_id) where accounts.acct_id='$COOKIE->{ACCT}' and acctype<'2000' group by acctype order by acctype");
$Stmts->execute;
$Stmt = $Stmts->fetchall_arrayref({});
$Stmts->finish;

($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});
$Companies = $dbh->prepare("select date_format(date_sub(comyearend,interval 1 year),'%d-%b-%y') as yearend from companies where reg_id=$Reg_id and id=$Com_id");
$Companies->execute;
$Company = $Companies->fetchrow_hashref;
$Companies->finish;

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
        WRAPPER => 'header.tt',
});

$Vars = {
        title => 'Add Opening Balances',
	cookie => $COOKIE,
	focus => 'obdesc',
	coas => $Coa,
	companies => $Company,
	stmts => $Stmt,
        javascript => '<style>
.mand2 { background-color:#f8e8c8; }
</style>
<script type="text/javascript">
var item_rows = [];
var tbl;
$(document).ready(function () {
  $("#obdate").datepicker();
});
function process_balance() {
  var errs = "";
  $(".mand2").each(function() {
    if (this.value.length < 1) { errs = errs + "<li>Empty " + this.title + "</li>"; }
  });
  $(".curr2").each(function() {
    if (! /^\d+?\.?\d?\d$/.test(this.value)) { errs = errs + "<li>Invalid Currency Field</li>"; }
  });
  if ($("#blk_nomcode").val() == "0") {
    errs = errs + "<li>Nominal Account not selected</li>";
  }
  if (errs.length > 0) {
    $("#dialog").html("You have the following errors<ol>" + errs + "</ol>");
    $("#dialog").dialog("open");
  }
  else {
    add_balance();
  }
}
function display_table() {
  var item_table = "";
  var bkgd = ["odd","even"];

  for (var i=0; i<item_rows.length; i++) {
    item_table = item_table + "<tr class=\'" + bkgd[i % 2] + "\'>";
    for (var j=0;j<3; j++) {
      if (item_rows[i][j] == undefined) {
        item_table = item_table + "<td>&nbsp;</td>";
      }
      else {
        if (j == 2) {
          item_table = item_table + "<td style=\'text-align:right;\'>" + item_rows[i][j] + "</td>";
        }
        else {
          item_table = item_table + "<td>" + item_rows[i][j] + "</td>";
        }
      }
    }
    item_table = item_table + "<td style=\'text-align:center;\'><input type=\'button\' value=\'Amd\' onclick=\"amd(\'" + i + "\');\"/>&nbsp;<input type=\'button\' value=\'Del\' onclick=\"dlt(\'" + i + "\');\"/></td>\\n</tr>";
  }
  $("#new").html(item_table);
  document.getElementById("blk_data").value = item_table;
}

function add_balance() {
  var item_row;
  var amt = document.getElementById("obamt").value * 1;
  var earnings = $("#balance").text() * 1;
  var nomcode = $("#blk_nomcode").val() * 1;
  if (nomcode < 2000) {
    earnings = earnings + amt;
  }
  else {
    earnings = earnings - amt;
  }
  $("#balance").html(earnings.toFixed(2));

  document.getElementById("obamt").value = amt.toFixed(2);
  item_row = [document.getElementById("blk_nomcode").value,document.getElementById("obdesc").value+" (Opening Balance)",document.getElementById("obamt").value];

  item_rows.push(item_row);
  display_table();
  document.getElementById("obdesc").value = "";
  document.getElementById("obamt").value = "";
  document.getElementById("obdesc").focus();
  
}

function amd(row) {
  $("#blk_nomcode").val(item_rows[row][0]);
  $("#obdesc").val(item_rows[row][1]);
  $("#obamt").val(item_rows[row][2]);

  dlt(row);
}
function dlt(row) {
  item_rows.splice(row,1);
  display_table();
}
function check_data() {
  if (document.getElementById("blk_data").value.length > 1) {
    return true;
  }
  else {
    $("#dialog").html("You have not entered any Opening Balances!");
    errfocus = "obdesc";
    $("#dialog").dialog("open");
    return false;
  }
}
</script>'
};

print "Content-Type: text/html\n\n";
$tt->process('bulk_opening_balances.tt',$Vars);

$dbh->disconnect;
exit;

