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

$Cookie = $Cookie{'fpa-uid'};

use Template;
$tt = Template->new({
	INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
	WRAPPER => 'wrapper.tt',
});

##	errmsg => 'You must enter both your login id (your email address) and your password',
$Vars = {
	 ads => $Adverts,
	title => 'Login - Step 1',
	cookie => $Cookie,
	javascript => '<script language="JavaScript">
function validate() {
  var errs = "";
  if (document.getElementById("email").value.length < 1) {
    errs = errs + "  -  No Email Address\\r\\n";
  }
  if (document.getElementById("pwd").value.length < 1) {
    errs = errs + "  -  No Password\\r\\n";
  }

  if (errs.length > 0) {
    alert("You have the following error(s):\\r\\n\\r\\n" + errs + "\\r\\nPlease Re-enter");
  }
  else {
    document.getElementById("form1").submit();
  }
}
</script>',
	errmsg => $Err_msg,
};
print "Content-Type: text/html\n\n";
$tt->process('login.tt',$Vars);
exit;
