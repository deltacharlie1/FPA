#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to display the invoices report input screen

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");
unless ($COOKIE->{NO_ADS}) {
	require "/usr/local/git/fpa/cgi/display_adverts.ph";
	&display_adverts();
}


#  Set up the array of hashes for company year end

$Dates = $dbh->prepare("select date_format(date_sub(now(),interval 6 month),'%d-%b-%y'),date_format(now(),'%d-%b-%y')");
$Dates->execute;
($Start_date,$End_date) = $Dates->fetchrow;
$Dates->finish;

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
	WRAPPER => 'header.tt'
});

$Vars = {
        title => 'Accounts - Invoice Analysis',
	cookie => $COOKIE,
	focus => 'invcusname',
        startdate => $Start_date,
        enddate => $End_date,
        javascript => '<script type="text/javascript"> 
$(document).ready(function(){
  $("#startdate").datepicker({ minDate: new Date(2000,01 - 1,01) });
  $("#enddate").datepicker({ minDate: new Date(2000,01 - 1,01) });
  redisplay("S");
});
function get_results(action) {
  document.getElementById("action").value = action;
  $.get("/cgi-bin/fpa/invrep2.pl",$("form#form1").serialize() ,function(data) {
    var parts = data.split("\t");
    document.getElementById("numrows").value = parts[0];
    document.getElementById("offset").value = parts[1];
    document.getElementById("action").value = "S";
    document.getElementById("sumtotal").value = parts[4];
    document.getElementById("results").innerHTML = parts[5];
  });
}
function redisplay(action) {
  if (/^\d+$/.test(action)) {
    if ((action - 1) * document.getElementById("rows").value < document.getElementById("numrows").value) {
      get_results(action);
    }
    else {
      alert("Page count is too high");
    }
  }
  else {
    get_results(action.substring(0,1));
  }
}
</script>'
};

print "Content-Type: text/html\n\n";
$tt->process('invrep1.tt',$Vars);

$dbh->disconnect;
exit;

