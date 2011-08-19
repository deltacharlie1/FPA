#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to display the main cover sheet updating screen

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");
unless ($COOKIE->{NO_ADS}) {
	require "/usr/local/git/fpa/cgi/display_adverts.ph";
	&display_adverts();
}


($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});
$Companies = $dbh->prepare("select comacccompleted from companies where reg_id=$Reg_id and id=$Com_id");
$Companies->execute;
@Company = $Companies->fetchrow;
$Companies->finish;
$dbh->disconnect;

$Start_date = `date +01-%b-%y`;
chomp($Start_date);

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
        WRAPPER => 'header.tt',
});

$Vars = {
        title => 'Accounts - Opening Balances',
	cookie => $COOKIE,
	comacccompleted => $Company[0],
	startdate => $Start_date,
	focus => 'x1300',
        javascript => '<script type="text/javascript" src="/js/jquery-form.js"></script> 
<script type="text/javascript">
var responseText = "";
var errfocus = "";
$(document).ready(function(){
  $("#cdate").datepicker();
  var options = {
    beforeSubmit: validate,
    success: showResponse
  };
  $("#form1").ajaxForm(options);
});
function ob_dialog() {
  document.getElementById("dialog").innerHTML = "<p style=\'font-weight:normal;\'>Long Term Liabilities are long term loans, mortgages etc that have to be paid back over periods longer than one year</p>";
  $("#dialog").dialog("option","title","Long Term Liabilities");
  $("#dialog").dialog("open");
}

function showResponse(responseText, statusText) {
  if (/OK/i.test(responseText)) {
    location.href = "/cgi-bin/fpa/dashboard.pl";
  }
  else {
    document.getElementById("dialog").innerHTML = responseText;
    $("#dialog").dialog("open");
  }
}
function validate(formData,jqForm,options) {
  return validate_form("#form1");
}
</script>',
};

print "Content-Type: text/html\n\n";
$tt->process('opening_balances.tt',$Vars);
exit;

