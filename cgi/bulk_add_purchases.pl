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

$Customers = $dbh->prepare("select id,cusname from customers where acct_id='$COOKIE->{ACCT}' order by cusname;");
$Customers->execute;

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
        WRAPPER => 'header.tt',
});

$Vars = {
        title => 'Add Invoicies',
	cookie => $COOKIE,
	focus => 'blk_invcusname',
	customers => $Customers->fetchall_arrayref({}),
        javascript => '<style>
.mand2 { background-color:#f8e8c8; }
</style>
<script type="text/javascript">
var item_rows = [];
var tbl;
$(document).ready(function () {
  $("#blk_invcusname").autocomplete({
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
      $.get("/cgi-bin/fpa/getcustomer.pl",{ id: ui.item.id }, function(data) {
        document.getElementById("blk_invcus_id").value = data.id;
        document.getElementById("blk_invcusname").value = data.cusname;
        document.getElementById("blk_invdesc").focus();
      });
    }
  });

  $("#blk_invdate").datepicker();
});
function calc_bvat() {
  if (document.getElementById("blk_netamt").value.length > 0) {
    var vat = document.getElementById("blk_netamt").value * document.getElementById("blk_vatrate").value;
    document.getElementById("blk_netamt").value = (document.getElementById("blk_netamt").value * 1).toFixed(2);
    document.getElementById("blk_netvat").value = vat.toFixed(2);
    document.getElementById("blk_totamt").value = ((document.getElementById("blk_netamt").value * 1) + (vat.toFixed(2) * 1)).toFixed(2);
  }
  else {
    if (document.getElementById("blk_netamt").value.length==0 && (document.getElementById("blk_netvat").value.length==0 && document.getElementById("blk_totamt").value.length > 0)) {
      if (document.getElementById("blk_vatrate").value * 1 > 0) {
        var net = (document.getElementById("blk_totamt").value / (1 + (document.getElementById("blk_vatrate").value * 1))).toFixed(2);
        var vat = ((document.getElementById("blk_totamt").value * 1) - net).toFixed(2);
        document.getElementById("blk_netamt").value = net;
        document.getElementById("blk_netvat").value = vat;
        document.getElementById("blk_totamt").value = (document.getElementById("blk_totamt").value * 1).toFixed(2);
      }
      else {
        document.getElementById("blk_netvat").value = "0";
        document.getElementById("blk_totamt").value = (document.getElementById("blk_totamt").value * 1).toFixed(2);
        document.getElementById("blk_netamt").value = document.getElementById("blk_totamt").value;
      }
    }
  }
}
function process_invoice() {
  var errs = "";
  $(".mand2").each(function() {
    if (this.value.length < 1) { errs = errs + "<li>Empty " + this.title + "</li>"; }
  });
  if (errs.length > 0) {
    document.getElementById("dialog").innerHTML = "You have the following errors<ol>" + errs + "</ol>";
    $("#dialog").dialog("open");
  }
  else {
    add_invoice();
  }
}
function display_table() {
  var item_table = "";
  var bkgd = ["odd","even"];

  for (var i=0; i<item_rows.length; i++) {
    item_table = item_table + "<tr class=\'" + bkgd[i % 2] + "\'>";
    for (var j=0;j<14; j++) {
      if (item_rows[i][j] == undefined) {
        item_table = item_table + "<td>&nbsp;</td>";
      }
      else {
        if (j==2 || j==3 || j==10 || j==11 || j==13 || (document.getElementById("blk_vatrate").value=="" && (j==5 || j==6))) {
          item_table = item_table + "<td style=\'display:none;\'>" + item_rows[i][j] + "</td>";
        }
        else {
          if (j == 12) {
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
  document.getElementById("blk_data").value = item_table;
  document.getElementById("blk_invcusname").focus();
}

function add_invoice() {
  var item_row;
  var pfflag = "";
  if ($("#blk_pfflag").attr("checked")) {
    pfflag = "Y";
  }
  item_row = [document.getElementById("blk_nomcode").value,document.getElementById("blk_invcusname").value,document.getElementById("blk_invcus_id").value,"",document.getElementById("blk_invdesc").value,document.getElementById("blk_netamt").value,document.getElementById("blk_netvat").value,document.getElementById("blk_totamt").value,document.getElementById("blk_invdate").value,document.getElementById("blk_txnmethod").value,document.getElementById("blk_invcat").value,document.getElementById("blk_invref").value,pfflag,document.getElementById("blk_vatrate").value];

  item_rows.push(item_row);
  display_table();
  if ($("input[name=\'clear\']:checked").val() == "Y") {
    document.getElementById("blk_invcusname").value = "";
    document.getElementById("blk_invcus_id").value = "";
    document.getElementById("blk_invdesc").value = "";
    document.getElementById("blk_netamt").value = "";
    document.getElementById("blk_netvat").value = "";
    document.getElementById("blk_totamt").value = "";
    document.getElementById("blk_invdate").value = "";
    document.getElementById("blk_invcat").value = "";
    document.getElementById("blk_invref").value = "";
    $("input[name=pfflag]").attr("checked",true);
  }
}

function amd(row) {
  $("#blk_nomcode").val(item_rows[row][0]);
  $("#blk_invcusname").val(item_rows[row][1]);
  $("#blk_invcus_id").val(item_rows[row][2]);
  $("#blk_invdesc").val(item_rows[row][4]);
  $("#blk_netamt").val(item_rows[row][5]);
  $("#blk_netvat").val(item_rows[row][6]);
  $("#blk_totamt").val(item_rows[row][7]);
  $("#blk_invdate").val(item_rows[row][8]);
  $("#blk_txnmethod").val(item_rows[row][9]);
  $("#blk_invcat").val(item_rows[row][10]);
  $("#blk_invref").val(item_rows[row][11]);
  if (item_rows[row][12] == "Y") {
    $("input[name=pfflag]").attr("checked",true);
  }
  else {
    $("input[name=pfflag]").attr("checked",false);
  }
  $("#blk_vatrate").val(item_rows[row][13]);

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
    document.getElementById("dialog").innerHTML = "You have not entered any invoices!";
    errfocus = "blk_invcusname";
    $("#dialog").dialog("open");
    return false;
  }
}
</script>',
};

print "Content-Type: text/html\n\n";
$tt->process('bulk_add_purchases.tt',$Vars);

$Customers->finish;
$dbh->disconnect;
exit;

