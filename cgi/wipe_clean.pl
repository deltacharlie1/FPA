#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to display Contact Details (for eventual updating)

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
        WRAPPER => 'header.tt',
});

$Vars = {
	 ads => $Adverts,
        title => 'Accounts - Wipe Clean',
	cookie => $COOKIE,
        javascript => '<script type="text/javascript" src="/js/jquery-form.js"></script> 
<script type="text/javascript">
var responseText = "";
var errfocus = "";
$(document).ready(function(){
  var options = {
    beforeSubmit: validate,
    success: showResponse
  };
  $("#form1").ajaxForm(options);
});
function showResponse(responseText, statusText) {
  if (/OK/i.test(responseText)) {
    var href = responseText.split("-");
    location.href = "/cgi-bin/fpa/dashboard.pl";
  }
  else {
    $("#dialog").html(responseText);
    $("#dialog").dialog("open");
  }
}
function validate(formData,jqForm,options) {
  return validate_form("#form1");
}
function setfocus() {
  eval("document.getElementById(\'" + errfocus + "\').focus();");
}
</script>',
};

print "Content-Type: text/html\n\n";
$tt->process('wipe_clean.tt',$Vars);

exit;

