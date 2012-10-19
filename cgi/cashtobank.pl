#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to display Funds transfer screen

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

$Tfrtype = $ENV{QUERY_STRING};

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");

$Txns = $dbh->prepare("select date_format(txndate,'%d-%b-%y') as tdate,concat(txncusname,' (',txnremarks,')') as txncusname,txnamount from transactions where txnmethod in ('1200','1300') and acct_id=? order by txncreated desc limit 0,15");
$Txns->execute("$COOKIE->{ACCT}");

$Cheques = $dbh->prepare("select id,txncusname,txnremarks,txnamount,date_format(txndate,'%d-%b-%y') as txndte from transactions where acct_id='$COOKIE->{ACCT}' and txnmethod='1310' and txnbanked='' order by txndate");
$Cheques->execute;

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
        WRAPPER => 'header.tt',
});

$Vars = {
	 ads => $Adverts,
        title => 'Accounts - Transactions',
	cookie => $COOKIE,
tfrtype => $Tfrtype,
	entries => $Txns->fetchall_arrayref({}),
	cheques => $Cheques->fetchall_arrayref({}),
	focus => 'tframt',
	javascript => '<script type="text/javascript" src="/js/jquery-form.js"></script>
<script type="text/javascript">
$(document).ready(function() {
  calc_tot();
  var options = {
    beforeSubmit: validate,
    success: showResponse
  };
  $("#form1").ajaxForm(options);
  $("#tfrdate").datepicker();
});
function showResponse(responseText, statusText) {
  if (/OK/.test(responseText)) {
    $("#dialog").bind( "dialogclose", function() {
      location.href="/cgi-bin/fpa/list_txns.pl";
    });
    $("#dialog").dialog( "option", "title", "Transaction Completed");
    $("#dialog").dialog( "option", "modal", true);
    $("#dialog").html(responseText.replace(/OK-/i,""));
    $("#dialog").dialog("open");
  }
  else {
    $("#dialog").html(responseText);
  }
}
function validate(formData,jqForm,options) {
return validate_form("#form1");
}
function calc_tot() {
  var tot = 0;
  var td_id = "";
  $("input:checkbox").each(function() {
    if (this.checked) {
      tot = tot + parseFloat($(this).val());
    }
  });
  $("#chktot").html(tot.toFixed(2));
  if (document.getElementById("tframt").value.length > 0) {
    tot = tot + parseFloat(document.getElementById("tframt").value);
  }
  $("#tottot").html(tot.toFixed(2));
}
</script>'
};

print "Content-Type: text/html\n\n";
$tt->process('cashtobank.tt',$Vars);

$Txns->finish;
$Cheques->finish;

$dbh->disconnect;
exit;

