#!/usr/bin/perl

#  script to register an account
use Template;
$tt = Template->new({
	INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
	WRAPPER => 'logicdesign.tt',
});

$Vars = {
	title => 'Register',
	focus => 'email',
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
    height: 200,
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
                        document.getElementById("dialog").innerHTML = responseText;
                        $("#dialog").dialog("open");
                }
                else {
                        document.getElementById("login").innerHTML = responseText;
                        var options = {
                                beforeSubmit: validate,
                                success:        showResponse
                        };
                }
        }
}
function validate() {
  var errs = "";
  var emailTemplate = /^[\w\-\.\+]+\@[a-zA-Z0-9\.\-]+\.[a-zA-z0-9]{2,4}$/;
  $(".error").removeClass("error");
  $(".mandatory").each(function(i)
    {
      if (this.value.length < 1) {
        errs = errs + "<li>Empty " + this.title + "<\/li>";
        $(this).parent().addClass("error");
        if (errfocus.length < 1) {
                errfocus = this.name;
        }
      }
      else {
        if (this.name == "email") {
          if (! document.getElementById("email").value.match(emailTemplate)) {
            errs = errs + "<li>Email Address not in the correct format<\/li>";
            $(this).parent().addClass("error");
            if (errfocus.length < 1) {
              errfocus = this.name;
            }
          }
        }
        if (this.name == "tc" && ! this.checked) {
          errs = errs + "<li>You have not Accepted our Terms &amp; Conditions<\/li>";
          $(this).parent().addClass("error");
          if (errfocus.length < 1) {
            errfocus = this.name;
          }
        }
        if (this.name == "pwd1") {
          var bad_pwd = false;
          if (this.value.length < 6) {
            errs = errs + "<li>Your password must be at least 6 characters in length<\/li>";
            bad_pwd = true;
          }
          if (this.value != document.getElementById("pwd2").value) {
            errs = errs + "<li>Your Password and password confirmation do not match<\/li>";
            bad_pwd = true;
          }
          if (/\'/.test(this.value)) {
            errs = errs + "<li>Your password cannot contain an apostrophe (\')<\/li>";
            bad_pwd = true;
          }
          if (bad_pwd) {
            $(this).parent().addClass("error");
            if (errfocus.length < 1) {
              errfocus = this.name;
            }
          }
        }
        if (this.name == "mem1") {
          var bad_mem = false;
          if (this.value.length < 8) {
            errs = errs + "<li>Your Memorable word must be at least 8 characters in length<\/li>";
            bad_mem = true;
          }
          if (this.value != document.getElementById("mem2").value) {
            errs = errs + "<li>Your Memorable word and memorable word confirmation do not match<\/li>";
            bad_mem = true;
          }
          if (! /^[a-zA-Z0-9 ]+$/.test(this.value)) {
            errs = errs + "<li>Your memorable word can only contain letters, numbers or a space<\/li>";
            bad_mem = true;
          }
          if (bad_mem) {
            $(this).parent().addClass("error");
            if (errfocus.length < 1) {
              errfocus = this.name;
            }
          }
        }
      }
    });

  if (errs.length > 0) {
    errs = "You have the following error(s):-<ol>" + errs + "<\/ol>Please correct them before re-submitting";
    document.getElementById("dialog").innerHTML = errs;
    $("#dialog").dialog("open");
    return false;
  }
  else {
    var form1flds = $("form#form1").serialize();
    var bonusflds = $(".bonus").serialize();
    if (bonusflds.length > 0) {
      form1flds = form1flds + "&" + bonusflds;
    }
    $.post("/cgi-bin/fpa/register2.pl", form1flds, function(data) {
      if (/^OK/.test(data)) {
        location.href="/registered.html";
      }
      else {
        document.getElementById("dialog").innerHTML = data;
        $("#dialog").dialog("open");
      }
    },"text");
  }
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
    document.getElementById("dialog").innerHTML = "You must enter the email address with which you originally registered";
    $("#dialog").dialog("open");
  }
  else {
    document.getElementById("react").value = "Y";
    $.post("/cgi-bin/fpa/register2.pl", $("form#form1").serialize(),function(data) {
      if (/^OK/.test(data)) {
        location.href="/registered.html";
      }
      else {
        document.getElementById("dialog").innerHTML = data;
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
