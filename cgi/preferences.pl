#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to display the registration screen tuned to reregistering

#  0 - Memword Check
#  1 - Login timeout
#  2 - paid in full flag
#  3 - display category field
#  4 - display upload button
#  5 - display adverts
#
#  regprefs is currently set by a database default of 'YYNYYY;


use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");
$Regs = $dbh->prepare("select regprefs from registrations where regemail='$COOKIE->{ID}'");
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
        title => 'Accounts - Preferences',
	cookie => $COOKIE,
	reg => $Reg,
        javascript => '<script type="text/javascript" src="/js/jquery-form.js"></script>
<script language="JavaScript">
$(document).ready(function(){
  var options = {
    success: showResponse
  };
  $("#form1").ajaxForm(options);
});
function showResponse(responseText, statusText) {
  $("#dialog").html(responseText);
  $("#dialog").dialog("open");
}
</script>'
};

print "Content-Type: text/html\n\n";
$tt->process('preferences.tt',$Vars);
$dbh->disconnect;
exit;

