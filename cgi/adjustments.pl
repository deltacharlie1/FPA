#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to add to / reduce loans and / or share capital 

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");

unless ($COOKIE->{NO_ADS}) {
        require "/usr/local/git/fpa/cgi/display_adverts.ph";
        &display_adverts();
}
$dbh->disconnect;

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
        WRAPPER => 'header.tt',
});

$Vars = {
        title => 'Adjustments',
	cookie => $COOKIE,
	focus => 'amtpaid',
	loantype => $ENV{QUERY_STRING},
        loan => $Coa->{'2300'},
        shares => $Coa->{'3000'},
        javascript => '<script type="text/javascript" src="/js/jquery-form.js"></script> 
<script language="JavaScript">
var responseText = "";
var errfocus = "";
$(document).ready(function(){
  var options = {
    beforeSubmit: validate,
    success: showResponse
  };
  $("#form1").ajaxForm(options);
  $("#txndate").datepicker();
  $("#paytype").change(function() {
    if (this.value == "1000") {
      $("#payblock").hide();
    }
    else {
      $("#payblock").show();
    }
  });
});
function showResponse(responseText, statusText) {
  if (/OK/i.test(responseText)) {
    var href = responseText.split("-");
    location.href = "/cgi-bin/fpa/" + href[1];
  }
  else {
    document.getElementById("dialog").innerHTML = responseText;
    $("#dialog").dialog("open");
    errfocus = "amtpaid";
  }
}
function validate(formData,jqForm,options) {
  return validate_form("#form1");
}
function check_receipt(obj) {
}
</script>',
};

print "Content-Type: text/html\n\n";
$tt->process('adjustments.tt',$Vars);
exit;

