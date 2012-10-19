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
	focus => 'tframt',
	javascript => '<script type="text/javascript" src="/js/jquery-form.js"></script>
<script type="text/javascript">
$(document).ready(function() {
  var options = {
    beforeSubmit: validate,
    success: showResponse
  };
  $("#form1").ajaxForm(options);
  $("#tfrdate").datepicker();
});
function showResponse(responseText, statusText) {
  window.location.reload(true);
}
function validate(formData,jqForm,options) {
  var errs = "";
  errfocus = "";
  $(".error").removeClass("error");
  $("#form1.mandatory").each(function(i)
    {
      if (this.value.length < 1) {
        errs = errs + "<li>Empty " + this.title + "<\/li>";
        $(this).parent().addClass("error");
        if (errfocus.length < 1) {
          errfocus = this.name;
        }
      }
    }
  );
  if (errs.length > 0) {
    errs = "You have the following error(s):-<ol>" + errs + "<\/ol>Please correct them before re-submitting";
    $("#dialog").html(errs);
    $("#dialog").dialog("open");
    return false;
  }
}
function setfocus() {
  eval("document.getElementById(\'" + errfocus + "\').focus();");
}

</script>'
};

print "Content-Type: text/html\n\n";
$tt->process('transfer.tt',$Vars);

$Txns->finish;
$dbh->disconnect;
exit;

