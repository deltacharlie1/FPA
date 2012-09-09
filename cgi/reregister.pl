#!/usr/bin/perl

$ACCESS_LEVEL = 0;

#  script to display the registration screen tuned to reregistering

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");
unless ($COOKIE->{NO_ADS}) {
	require "/usr/local/git/fpa/cgi/display_adverts.ph";
	&display_adverts();
}

$Regs = $dbh->prepare("select regusername,regemail,regmembership,regoptin,regmenutype from registrations where regemail='$COOKIE->{ID}'");
$Regs->execute;
$Reg = $Regs->fetchrow_hashref;
$Regs->finish;

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
        WRAPPER => 'header.tt',
});

$Vars = {
	 ads => $Adverts,
        title => 'Accounts - Registration Details',
	cookie => $COOKIE,
focus => 'pwd1',
	reg => $Reg,
        javascript => '<script type="text/javascript" src="/js/jquery-form.js"></script> 
<script language="JavaScript">
var responseText = "";
var errfocus = "";
$(document).ready(function(){
  var options = {
    beforeSubmit: reg_validate,
    success: showResponse
  };
  $("#reregform1").ajaxForm(options);
});
function check_optin() {
  if ($("#optin").val() == "N") {
    $("#dialog").dialog("option", "title", "Warning");
    $("#dialog").dialog("option","height",300);
    $("#dialog").dialog("option","width",400);
    $("#dialog").html("<p>WARNING - It is a condition of using the free version of FreePlus Accounts that you accept advertising and our newsletter.&nbsp;&nbsp;If you choose to opt out of receiving the newsletter you will not longer have access to any part of the free version other than this registration screen.</p><p>In order to continue using FreePlus Accounts you will need to select a \'paid for\' option (not currently available) or continue to accept the newsletter.</p>");
    $("#dialog").dialog("open");
  }
}
function showResponse(responseText, statusText) {
  if (/OK/i.test(responseText)) {
    var href = responseText.split("-");
    location.href = "/cgi-bin/fpa/" + href[1];
  }
  else {
    $("#dialog").html(responseText);
    $("#dialog").dialog("open");
  }
}
function reg_validate(formData,jqForm,options) {
  var errs = "";
  errfocus = "";
  $(".error").removeClass("error");
  $("#reregform1.mandatory").each(function(i)
    {
      if (this.value.length < 1) {
        if (/vat/.test(this.name)) {
          if (document.getElementById("comvatscheme").value != "N") {
            errs = errs + "<li>Empty " + this.title + "</li>";
            $(this).parent().addClass("error");
            if (errfocus.length < 1) {
              errfocus = this.name;
            }
          }
        }
        else {
          errs = errs + "<li>Empty " + this.title + "</li>";
          $(this).parent().addClass("error");
          if (errfocus.length < 1) {
            errfocus = this.name;
          }
        }
      }
    }
  );
  if (document.getElementById("pwd1").value.length > 0 && document.getElementById("pwd1").value != document.getElementById("pwd2").value) {
    errs = errs + "<li>Password and Password confirmation do not agree<\/li>";
    $("#pwd1").parent().addClass("error");
    $("#pwd2").parent().addClass("error");
    if (errfocus.length < 1) {
      errfocus = "pwd1";
    }
  }
  else {
    if (document.getElementById("pwd1").value.length > 0 && document.getElementById("pwd1").value.length < 6) {
      errs = errs + "<li>Password must be at least 6 characters long<\/li>";
      $("#pwd1").parent().addClass("error");
      if (errfocus.length < 1) {
        errfocus = "pwd1";
      }
    }
  }
  if (document.getElementById("mem1").value.length > 0 && document.getElementById("mem1").value != document.getElementById("mem2").value) {
    errs = errs + "<li>Memorable word and Memorable word confirmation do not agree<\/li>";
    $("#mem1").parent().addClass("error");
    $("#mem2").parent().addClass("error");
    if (errfocus.length < 1) {
      errfocus = "mem1";
    }
  }
  else {
    if (document.getElementById("mem1").value.length > 0 && document.getElementById("mem1").value.length < 8) {
      errs = errs + "<li>Memorable word must be at least 8 characters long<\/li>";
      $("#pwd1").parent().addClass("error");
      if (errfocus.length < 1) {
        errfocus = "pwd1";
      }
    }
  }
  if (! /^.+\@.+\.\w/.test(document.getElementById("email").value)) { 
    errs = errs + "<li>Your email is in an invalid foramat<\/li>";
    $("#email").parent().addClass("error");
    if (errfocus.length < 1) {
      errfocus = "pwd1";
    }
  }
  if (errs.length > 0) {
    errs = "You have the following error(s):-<ol>" + errs + "<\/ol>Please correct them before re-submitting";
    $("#dialog").html(errs);
    $("#dialog").dialog("open");
    return false;
  }
}
</script>',
};

print "Content-Type: text/html\n\n";
$tt->process('reregister.tt',$Vars);
$dbh->disconnect;
exit;

