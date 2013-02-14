#!/usr/bin/perl

$ACCESS_LEVEL = 3;

#  script to send an invoitation (a reminder with a remcode = GENINV) to an existing user

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");
($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});

if ($COOKIE->{BUS} == 1 && $COOKIE->{ACCESS} > 6) {
	$Limit = '10000';
}
elsif ($COOKIE->{BUS} == 1 && $COOKIE->{ACCESS} > 4) {
	$Limit = "150";
}
elsif ($COOKIE->{BUS} == 1 && $COOKIE->{ACCESS} > 2) {
	$Limit = "15";
}
elsif ($COOKIE->{BUS} == 1) {
	$Limit = "3";
}
else {
	$Limit = '1';
}

$Companies = $dbh->prepare("select id,reg_id,comname,comcontact,comemail,date_format(comyearend,'%b') as comyearend,comvatscheme,comvatduein,comcis from companies where companies.reg_id=$Reg_id order by comname limit $Limit");
$Companies->execute;
$Remaining = $Limit - $Companies->rows;

$Market_Sectors = $dbh->prepare("select id,sector,frsrate from market_sectors");
$Market_Sectors->execute;
$Sectors = $Market_Sectors->fetchall_arrayref({});
$Market_Sectors->finish;

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
        WRAPPER => 'header.tt',
});

$Vars = {
	 ads => $Adverts,
        title => 'Add Companies',
	cookie => $COOKIE,
	focus => 'email',
	sectors => $Sectors,
	companies => $Companies->fetchall_arrayref({}),
        javascript => '<script type="text/javascript">
var item_rows = [];
var tbl;
var remaining = '.$Remaining.';

function send_invite() {
  if (remaining < 1) {
      $("#dialog").dialog("option","title","Invitation Error");
      $("#dialog").html("You will need to upgrade your subscription before you can add further companies");
      $("#dialog").dialog("open");;
  }
  else {
    $.post("/cgi-bin/fpa/invite_existing_user2.pl", $("#form1").serialize(),function(data) {
      $("#dialog").dialog("option","title","Invitation Result");
      $("#dialog").html(data);
      $("#dialog").dialog("open");;
    },"text");

  }
}
</script>',
};

print "Content-Type: text/html\n\n";
$tt->process('invite_existing_user.tt',$Vars);

$Companies->finish;
$dbh->disconnect;
exit;

