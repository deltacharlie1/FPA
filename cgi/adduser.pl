#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to display the add user screen

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");
unless ($COOKIE->{NO_ADS}) {
	require "/usr/local/git/fpa/cgi/display_adverts.ph";
	&display_adverts();
}

$Regs = $dbh->prepare("select regusername,regemail,regmembership,regoptin,regmenutype from registrations where reg_id=$Reg_id");
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
        title => 'Accounts - Add User',
	cookie => $COOKIE,
	focus => 'addusername',
        javascript => '<script type="text/javascript">
var errfocus = "";
function submit_form(type) {
  if (validate_form("#form1")) {
    document.getElementById("addtype").value = type;
    $.post("/cgi-bin/fpa/adduser2.pl",$("#form1").serialize(), function(data) {
      if (/OK/i.test(data)) {
        var href = data.split("-");
        location.href = "/cgi-bin/fpa/" + href[1];
      }
      else {
        $("#dialog").html(data);
        $("#dialog").dialog("open");
      }
    },"text");
  }
}
</script>',
};

print "Content-Type: text/html\n\n";
$tt->process('adduser.tt',$Vars);
$dbh->disconnect;
exit;

