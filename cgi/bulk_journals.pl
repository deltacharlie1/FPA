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
        title => 'Journal Entriess',
	cookie => $COOKIE,
	focus => 'adjstdesc',
	coas => $COA,
	today => $Today,
        javascript => '<style>
.mand2 { background-color:#f8e8c8; }
.hd { font-weight:bold;font-size:1.2em;padding-left:3px; }
</style>
<script type="text/javascript">
$(document).ready(function() {
  $("#adjstdate").datepicker();
  $("#adjstcred option").css("display","none");
});

function enable_cred() {
  if ($("#d"+$("#adjstdeb").val()).hasClass("incx")) {
    $(".inc").css("display","none");
    $(".exp").css("display","inline");
  }
  else {
    $(".inc").css("display","inline");
    $(".exp").css("display","none");
  }
}

var item_rows = [];
var tbl;
var errfocus = "";

function display_table() {

  var totdeb = 0;
  var totcred = 0;

  var item_table = "";

  var bkgd = ["odd","even"];

  for (var i=0; i<item_rows.length; i++) {
    item_table = item_table + "<tr class=\'" + bkgd[i % 2] + "\'>";
    item_table = item_table + "<td>" + item_rows[i][0] + "</td>";
    item_table = item_table + "<td>" + item_rows[i][1] + "</td>";
    item_table = item_table + "<td>" + item_rows[i][2] + "</td>";
    item_table = item_table + "<td style=\'text-align:right;\'>" + item_rows[i][3] + "</td>";
    item_table = item_table + "<td style=\'display:none;\'>" + item_rows[i][4] + "</td>";
    item_table = item_table + "<td style=\'display:none;\'>" + item_rows[i][5] + "</td>";
    item_table = item_table + "<td>&nbsp;</td>";
    item_table = item_table + "<td nowrap=\'nowrap\' style=\'text-align:center;\'><img src=\'/icons/inv_edit.png\' title=\'Edit\' onclick=\"amd(\'" + i + "\');\"/>&nbsp;<img src=\'/icons/inv_del.png\' title=\'Delete\' onclick=\"dlt(\'" + i + "\');\"/></td></tr>";
    item_table = item_table + "<tr class=\'" + bkgd[i % 2] + "\'>";
    item_table = item_table + "<td>&nbsp;</td><td>&nbsp;</td>";
    item_table = item_table + "<td>" + item_rows[i][4] + "</td><td>&nbsp;</td>";
    item_table = item_table + "<td style=\'display:none;\'>&nbsp;</td><td style=\'display:none;\'>&nbsp;</td>";
    item_table = item_table + "<td style=\'text-align:right;\'>" + item_rows[i][5] + "</td>";
    item_table = item_table + "<td>&nbsp;</td></tr>";

    totdeb = totdeb + (item_rows[i][3] * 1);   
    totcred = totcred + (item_rows[i][5] * 1);   
  }
  $("#new").html(item_table);
  $("#totdeb").html(totdeb.toFixed(2));
  $("#totcred").html(totcred.toFixed(2));
  var bal = (totdeb - totcred).toFixed(2);
  $("#bal").html(bal);
  document.getElementById("data").value = item_table;
}

function add_entry() {
  var errs = "";
  errfocus = "";
  $(".mand2").each(function() {
    if ($(this).val()=="") {
      if (errfocus == "") {
        errfocus = this.id;
      }
      errs = errs + "<li>No " + this.title + "</li>\\n";
    }
  });
  if (errs != "") {
    errs = "You have the following errors:-<ul>" + errs + "</ul>";
    $("#dialog").html(errs);
    $("#dialog").dialog("open");
  }
  else {
    var item_row;
    item_row = [$("#adjstdate").val(),$("#adjstdesc").val(),$("#adjstdeb").val(),$("#adjstdebamt").val(),$("#adjstcred").val(),$("#adjstcredamt").val()];

    item_rows.push(item_row);
    display_table();

    document.getElementById("adjstdesc").value = "";
    document.getElementById("adjstcredamt").value = "";
    document.getElementById("adjstdebamt").value = "";
    $("#adjstdeb").val(-1);
    $("#adjstcred").val(-1);
  }
}

function amd(row) {
  $("#adjstdate").val(item_rows[row][0]);
  $("#adjstdesc").val(item_rows[row][1]);
  $("#adjstdeb").val(item_rows[row][2]);
  $("#adjstdebamt").val(item_rows[row][3]);
  $("#adjstcred").val(item_rows[row][4]);
  $("#adjstcredamt").val(item_rows[row][5]);

  dlt(row);
}
function dlt(row) {
  item_rows.splice(row,1);
  display_table();
}
function check_data() {
  if (document.getElementById("data").value.length > 1) {
    if ($("#bal").html() == "0.00" || confirm("Debits & Credits do not Balance!  Are you sure you want to continue?")) {
      alert("Good to go!");
    }
    return false;
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

