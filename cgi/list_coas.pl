#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to display Chart of Account details

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");

$Coas = $dbh->prepare("select id,coanominalcode,coadesc,coatype,coabalance from coas where acct_id=? order by coanominalcode");
$Coas->execute("$COOKIE->{ACCT}");

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
        WRAPPER => 'header.tt',
});

$Vars = {
	 ads => $Adverts,
        title => 'Accounts - Coas',
	cookie => $COOKIE,
	entries => $Coas->fetchall_arrayref({}),
        javascript => '<script type="text/javascript">
$(document).ready(function() {
  $("#changedescr").dialog({
    bgiframe: true,
    autoOpen: false,
    position: [200,100],
    height: 200,
    width: 400,
    modal: true,
    buttons: {
      "Change Description": function() {
        $.post("/cgi-bin/fpa/change_coadescr.pl", $("#fchangedescr").serialize(),function(data) {
          if ( ! /^OK/.test(data)) {
            alert(data);
          }
          window.location.reload(true);
        },"text");
        $(this).dialog("close");
      },
      Cancel: function() {
        $("td").removeClass("error");
        $(this).dialog("close");
      }
    }
  });
});
function change_descr(obj,id,olddescr) {
  $(obj).addClass("error");
  document.getElementById("cd_id").value = id;
  document.getElementById("newdescr").value = olddescr;
  $("#changedescr").dialog("open");
}
</script>'
};

print "Content-Type: text/html\n\n";
$tt->process('list_coas.tt',$Vars);

$Coas->finish;
$dbh->disconnect;
exit;

