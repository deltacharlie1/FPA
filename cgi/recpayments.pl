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

($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});

$Recpayments = $dbh->prepare("select * from recpayments where acct_id='$COOKIE->{ACCT}'");
$Recpayments->execute;
$Recpayment = $Recpayments->fetchall_arrayref({});
$Recpayments->finish;

$Accts = $dbh->prepare("select coanominalcode,coadesc from coas where acct_id='$COOKIE->{ACCT}' and coanominalcode like '12%' order by coanominalcode");
$Accts->execute;
$Acct = $Accts->fetchall_arrayref({});
$Accts->finish;

$Expenses = $dbh->prepare("select coanominalcode,coadesc from coas where acct_id='$COOKIE->{ACCT}' and coanominalcode > 4999 order by coanominalcode");
$Expenses->execute;
$Expense = $Expenses->fetchall_arrayref({});
$Expenses->finish;

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
        WRAPPER => 'header.tt',
});

$Vars = {
	 ads => $Adverts,
        title => 'Recurring Payments',
	cookie => $COOKIE,
	focus => 'blk_invcusname',
	recpayments => $Recpayment,
	accts => $Acct,
	expenses => $Expense,
        javascript => '<style>
.mand2 { background-color:#f8e8c8; }
</style>
<script type="text/javascript">
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
      document.getElementById("blk_reccus_id").value = ui.item.id;
    }
  });

  $("#recnextdate").datepicker();

  $.post("/cgi-bin/fpa/recpayments2.pl", $("#blk_form1").serialize(),function(data) {
    $("#new").html(data);
  },"text");
});
function add_paymt() {
  document.getElementById("recinit").value="U";
  var errs = "";
  errfocus = "";
  $(".mand2").each(function() {
    if (this.value.length < 1) {
      errs = errs + "<li>Empty " + this.title + "</li>";
      if (errfocus == "") {
        errfocus = this.id;
      }
    }
  });
  if (errs.length > 0) {
    $("#dialog").html("You have the following errors<ol>" + errs + "</ol>");
    $("#dialog").dialog("open");
  }
  else {
    $.post("/cgi-bin/fpa/recpayments2.pl", $("#blk_form1").serialize(),function(data) {
      if ( /errors/.test(data)) {
        $("#dialog").html(data);
        $("#dialog").dialog("open");
      }
      else {
        $("#new").html(data);
      }
    },"text");
    $("#blk_invcusname").val("");
    $("#reccus_id").val("");
    $("#blk_totamt").val("");
    $("#blk_recdesc").val("");
    $("#recvatrate").val("S");
    $("#recnextdate").val("");
    $("#recfreq").val("5");
    $("#rectxnmethod").val("1200");
    $("#reccoa").val("6000");
    $("#rectype").val("");
    $("#recref").val("");
  }
}
function dlt(id) {
  $.post("/cgi-bin/fpa/recpayments2.pl", { reccus_id: id, init: "D" },function(data) {
    $("#new").html(data);
  },"text");
}
</script>',
};

print "Content-Type: text/html\n\n";
$tt->process('recpayments.tt',$Vars);

$dbh->disconnect;
exit;

