#!/usr/bin/perl

#  script to register an account
use Template;
$tt = Template->new({
	INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
	WRAPPER => 'logicdesign.tt',
});
$Posts =  `php /usr/local/git/fpa/cgi/get_posts.php`;
$Posts =~ s/https/http/g;

$Vars = {
	 ads => $Adverts,
	title => 'Register',
	focus => 'email',
	posts => $Posts,
	javascript => '<script type="text/javascript" src="/js/jquery-form.js"></script> 
<script src="/js/jquery.cluetip.js" type="text/javascript"></script>
<script src="/js/jquery.watermark.js" type="text/javascript"></script>
<link rel="stylesheet" href="/css/jquery.cluetip.css" type="text/css"/>
<link rel="stylesheet" href="/css/login.css" type="text/css"/>
<script type="text/javascript">
var responseText = "";
var errfocus = "";
var bonusdisplayed = false;
$(document).ready(function() {
  $(".extra").cluetip({ 
    local: true,
    positionBy: "absolute",
    topOffset: 100,
    leftOffset: 350,
    width:375,
    titleAttribute: "rev",
    activation: "click",
    sticky: true,
    closePosition: "bottom",
    closeText: "<img src=\'/icons/cross.png\' alt=\'Close\' />"
  });
  $("#dialog").dialog({
    bgiframe: true,
    height: 360,
    width: 400,
    autoOpen: false,
    position: [200,100],
    modal: true,
    buttons: { "Ok": function() { $(this).dialog("close");setfocus(); } }
  });
  $("#bonusfeatures").dialog({
    bgiframe: true,
    height: 360,
    width: 400,
    autoOpen: false,
    position: [200,100],
    modal: true,
    buttons: { "Ok": function() { $(this).dialog("close");setfocus(); } }
  });
  $(".mandatory").before("<span style=\'font-size:20px;font-weight:bold;color:red;padding:0 6px 0 0;\'>*</span>");
  $("#pwd1").watermark("Min 6 characters");
  $("#mem1").watermark("Min 8 characters");
});
function showResponse(responseText, statusText) {
        if (/OK/i.test(responseText)) {
                var href = responseText.split("-");
                location.href = "/company_setup.html";
        }
        else {
                if (responseText.length < 500) {
                        $("#dialog").html(responseText);
                        $("#dialog").dialog("open");
                }
                else {
                        $("#login").html(responseText);
                        var options = {
                                beforeSubmit: validate,
                                success:        showResponse
                        };
                }
        }
}
function validate() {
}
function do_bonusfeatures() {
  if (! bonusdisplayed) {
    bonusdisplayed = true;
    $(".bonus").attr("checked",true);
  }
  $("#bonusfeatures").dialog("open");
}
function setfocus() {
  if (errfocus.length > 0) {
    eval("document.getElementById(\'" + errfocus + "\').focus();");
  }
}

function reactivate() {
  if (document.getElementById("email").value == "") {
    errfocus = "email";
    $("#dialog").html("You must enter the email address with which you originally registered");
    $("#dialog").dialog("open");
  }
  else {
    document.getElementById("react").value = "Y";
    $.post("/cgi-bin/fpa/register2.pl", $("form#form1").serialize(),function(data) {
      if (/^OK/.test(data)) {
        location.href="/registered.html";
      }
      else {
        $("#dialog").html(data);
        $("#dialog").dialog("open");
      }
    },"text");
  }
}
</script>'
};
print "Content-Type: text/html\n\n";
$tt->process('register.tt',$Vars);
exit;
