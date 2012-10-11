#!/usr/bin/perl

#  script to test template toolkit

$Err_msg = $ENV{QUERY_STRING};

@Cookie = split(/\;/,$ENV{HTTP_COOKIE});
foreach (@Cookie) {
        ($Name,$Value) = split(/\=/,$_);
        $Name =~ s/^ //g;
        $Value =~ tr/\"//d;
        $Cookie{$Name} = $Value;
}

#  Is this the local test system?


$Cookie = $Cookie{'fpa-uid'};
if ($Cookie) {
	$Focus = 'pwd';
}
else {
	$Focus = 'email';
}
use Template;
$tt = Template->new({
	INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
	WRAPPER => 'logicdesign.tt',
});
$Posts =  `php /usr/local/git/fpa/cgi/get_posts.php`;
$Posts =~ s/https/http/g;
if (`hostname -i` =~ /^192/) {
	$Posts = "Local Test System";;
}

#	posts => `php /usr/local/git/fpa/cgi/get_posts.php`,

$Vars = {
	 ads => $Adverts,
	title => 'Login',
	cookie => $Cookie,
	focus => $Focus,
	posts => $Posts,
	javascript => '<script type="text/javascript" src="/js/jquery-form.js"></script> 
<link rel="stylesheet" style="text/css" href="/css/login.css"/>
<script type="text/javascript">
var responseText = "";
var errfocus = "";
$(document).ready(function() {
  $("#dialog").dialog({
    bgiframe: true,
    height: 250,
    width: 400,
    autoOpen: false,
    position: [200,100],
    modal: true,
    buttons: { "Ok": function() { $(this).dialog("close");setfocus(); } }
  });
  $(".mandatory").before("<span style=\'font-size:20px;font-weight:bold;color:red;padding:0 6px 0 0;\'>*</span>");
  var options = {
    beforeSubmit: validate,
    success:	showResponse
  };
  $("#form1").ajaxForm(options);
});
function showResponse(responseText, statusText) {
	if (/XqQsOK/i.test(responseText)) {
		var href = responseText.split("-");
		location.href = "/cgi-bin/fpa/" + href[1];
	}
	else {
		if (responseText.length < 500) {
    			$("#dialog").html(responseText);
			$("#dialog").dialog("open");
		}
		else {
			$("#frmlogin").html(responseText);
			var options = {
				beforeSubmit: validate,
				success:	showResponse
			};
			$("#form1").ajaxForm(options);
		}
	}
}
function validate(formData,jqForm,options) {
  var errs = "";
  errfocus = "";
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
	if (/log in again/i.test($("#dialog").html())) {
		location.href = "/cgi-bin/fpa/login.pl";
	}
	else {
		eval("document.getElementById(\'" + errfocus + "\').focus();");
	}
}
</script>',
	errmsg => $Err_msg,
};
print "Content-Type: text/html\n\n";
$tt->process('login.tt',$Vars);
exit;
