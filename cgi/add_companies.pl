#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to list invoices

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");
unless ($COOKIE->{NO_ADS}) {
	require "/usr/local/git/fpa/cgi/display_adverts.ph";
	&display_adverts();
}

($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});

if ($COOKIE->{BUS} == 1 && $COOKIE->{ACCESS} > 6) {
	$Limit = '10000';
}
elsif ($COOKIE->{BUS} == 1 && $COOKIE->{ACCESS} > 4) {
	$Limit = "150";
}
elsif ($COOKIE->{BUS} == 1 && $COOKIE->{ACCESS} > 2) {
	$Limit = "15";
}
elsif ($COOKIE->{BUS} == 1) {
	$Limit = "3";
}
else {
	$Limit = '1';
}

$Companies = $dbh->prepare("select id,reg_id,comname,comcontact,comemail,date_format(comyearend,'%b') as comyearend,comvatscheme,comvatduein,comcis from companies where companies.reg_id=$Reg_id order by comname limit $Limit");
$Companies->execute;
$Remaining = $Limit - $Companies->rows;

$Market_Sectors = $dbh->prepare("select id,sector,frsrate from market_sectors");
$Market_Sectors->execute;
$Sectors = $Market_Sectors->fetchall_arrayref({});
$Market_Sectors->finish;

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
        WRAPPER => 'header.tt',
});

$Vars = {
        title => 'Add Companies',
	cookie => $COOKIE,
	focus => 'company',
	sectors => $Sectors,
	companies => $Companies->fetchall_arrayref({}),
        javascript => '<script type="text/javascript">
var item_rows = [];
var tbl;
var remaining = '.$Remaining.';

function display_table() {
  var item_table = "";
  var vatqend = [];
  vatqend[1] = "Jan/Apr/Jul/Oct";
  vatqend[2] = "Feb/May/Aug/Nov";
  vatqend[3] = "Mar/Jun/Sep/Dec";

  var bkgd = ["odd","even"];

  for (var i=0; i<item_rows.length; i++) {
    item_table = item_table + "<tr class=\'" + bkgd[i % 2] + "\'>";
    for (var j=0;j<8; j++) {
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
            if (j == 7) {
              item_table = item_table + "<td style=\'display:none;\'>" + item_rows[i][j] + "</td>";
            }
            else {
              item_table = item_table + "<td>" + item_rows[i][j] + "</td>";
            }
          }
        }
      }
    }
    item_table = item_table + "<td nowrap=\'nowrap\' style=\'text-align:center;\'><input type=\'button\' value=\'Amd\' onclick=\"amd(\'" + i + "\');\"/>&nbsp;<input type=\'button\' value=\'Del\' onclick=\"dlt(\'" + i + "\');\"/></td></tr>";
  }
  $("#new").html(item_table);
  document.getElementById("data").value = item_table;
}

function add_company() {
  if (remaining < 1) {
    alert("You will need to upgrade your subscription before you can add further companies");
  }
  else {
    remaining = remaining - 1;
    var errs;
    if (validate_form("#form1")) {
      var item_row;
      item_row = [document.getElementById("company").value,document.getElementById("client").value,document.getElementById("email").value,document.getElementById("yearend").value,document.getElementById("vatscheme").value,document.getElementById("vatend").value,$("input:radio[name=cis]:checked").val(),document.getElementById("combusiness").value];

      item_rows.push(item_row);
      display_table();

      document.getElementById("company").value = "";
      document.getElementById("client").value = "";
      document.getElementById("email").value = "";
      document.getElementById("yearend").value = "";
      document.getElementById("vatscheme").value = "N";
      document.getElementById("vatend").value = "";
      $("#cisN").attr("checked",true);
      $("#sectors").hide();
      $("#combusiness").removeClass("mandatory");
      $("#vatend").removeClass("mandatory");
      document.getElementById("combusiness").value = "";
    }
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
  $("#combusiness").val(item_rows[row][7]);
  if (/F/i.test(item_rows[row][4])) {
    $("#sectors").show();
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
    $("#dialog").html("You have not entered any company details!");
    errfocus = "company";
    $("#dialog").dialog("open");
    return false;
  }
}
function showhide_sectors(obj) {
  if (/N/i.test(obj.value)) {
    $("#vatend").removeClass("mandatory");
  }
  else {
    $("#vatend").addClass("mandatory");
  }
  if (/F/i.test(obj.value)) {
    $("#sectors").show();
    $("#combusiness").addClass("mandatory");
  }
  else {
    $("#sectors").hide();
    $("#combusiness").removeClass("mandatory");
  }
}
</script>',
};

print "Content-Type: text/html\n\n";
$tt->process('add_companies.tt',$Vars);

$Companies->finish;
$dbh->disconnect;
exit;

