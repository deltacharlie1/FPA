#!/usr/bin/perl

#  script to confirm registration of a new client

use Template;

use DBI;
my $dbh = DBI->connect("DBI:mysql:fpa");

#  First let's see if this activation code matches what we have in add_users

$Add_users = $dbh->prepare("select * from add_users where addactive='P' and addactivecode=? limit 1");
$Add_users->execute("$ENV{QUERY_STRING}");
$Add_user = $Add_users->fetchrow_hashref;

#  Show error message if this does not exist

unless ($Add_users->rows > 0) {
#  Show error message

}
else {
	
$tt = Template->new({
	INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
	WRAPPER => 'phoenix.tt',
});

#  Confirm whether or not they are already registered

	$Regs = $dbh->prepare("select * from registrations where regemail='$Add_user->{addemail}'");
	$Regs->execute;

	if ($Regs->rows > 0) {

#  Does exist so just ask for password confirmation

		$Vars = {
			title => 'User Activation',
			code => "$ENV{QUERY_STRING}",
			focus => 'pwd1',
			name => "$Add_user->{addusername}",
			email => "$Add_user->{addemail}",
			tag => "$Add_user->{addcomname}",
		        javascript => '<script type="text/javascript" src="/js/jquery-form.js"></script> 
<script src="/js/jquery.cluetip.js" type="text/javascript"></script>
<script src="/js/jquery.watermark.js" type="text/javascript"></script>
<link rel="stylesheet" href="/css/jquery.cluetip.css" type="text/css"/>
<script type="text/javascript">
var responseText = "";
var errfocus = "";
$(document).ready(function() {
  $("#dialog").dialog({
    bgiframe: true,
    height: 200,
    autoOpen: false,
    position: [200,100],
    modal: true,
    buttons: { "Ok": function() { $(this).dialog("close");setfocus(); } }
  });
  $(".mandatory").before("<span style=\'font-size:20px;font-weight:bold;color:red;padding:0 6px 0 0;\'>*</span>");
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
        if (this.name == "pwd1") {
          var bad_pwd = false;
          if (this.value.length < 6) {
            errs = errs + "<li>Your password must be at least 6 characters in length<\/li>";
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
      }
    });

  if (errs.length > 0) {
    errs = "You have the following error(s):-<ol>" + errs + "<\/ol>Please correct them before re-submitting";
    document.getElementById("dialog").innerHTML = errs;
    $("#dialog").dialog("open");
    return false;
  }
  else {
    $.post("/cgi-bin/fpa/confirmuser2.pl", $("form#form1").serialize(),function(data) {
      if (/^OK/.test(data)) {
        var msg = data.split("-");
        document.getElementById("dialog").innerHTML = data;
        $("#dialog").dialog("option","title","Information");
        $("#dialog").dialog("open");
        location.href="/cgi-bin/fpa/login.pl";
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

		print<<EOD;
Content-Type: text/html

EOD
		$tt->process('confirmuser1.tt',$Vars);

	}
	else {

		$Vars = {
			title => 'User Activation',
			code => "$ENV{QUERY_STRING}",
			focus => 'pwd1',
			name => "$Add_user->{addusername}",
			email => "$Add_user->{addemail}",
			tag => "$Add_user->{addcomname}",
		        javascript => '<script type="text/javascript" src="/js/jquery-form.js"></script> 
<script src="/js/jquery.cluetip.js" type="text/javascript"></script>
<script src="/js/jquery.watermark.js" type="text/javascript"></script>
<link rel="stylesheet" href="/css/jquery.cluetip.css" type="text/css"/>
<script type="text/javascript">
var responseText = "";
var errfocus = "";
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
  $(".mandatory").before("<span style=\'font-size:20px;font-weight:bold;color:red;padding:0 6px 0 0;\'>*</span>");
  $("#pwd2").watermark("Min 6 characters");
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
    $.post("/cgi-bin/fpa/confirmuser2.pl", $("form#form1").serialize(),function(data) {
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

#  Doesn't exist so display new registration screen

		print<<EOD;
Content-Type: text/html
Set-Cookie: fpa-uid=$FORM{email}; path=/; expires=$Add_user->{addemail};

EOD
		$tt->process('confirmuser2.tt',$Vars);

	}
	$Regs->finish;
}
$Add_users->finish;
$dbh->disconnect;
exit;
