#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to display the invoices report input screen

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});

use DBI;
my $dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");

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
  $("#cussrch").autocomplete({
    minLength: 1,
    delay: 50,
    source: function (request,response) {
      request.type = "Customers";
      $.ajax({
        url: "/cgi-bin/fpa/autosuggest.pl",
        dataType: "json",
        data: request,
        success: function( data ) {
          response (data);
        }
      });
    },
    select: function(event, ui) {
      document.getElementById("cusname").value = ui.item.id;
    }
  });
  redisplay("S");
});
function get_results(action) {
  document.getElementById("action").value = action;
  $.get("/cgi-bin/fpa/assign_invoices2.pl",$("form#form1").serialize() ,function(data) {
    document.getElementById("results").innerHTML = data;
  });
}
function redisplay(action) {
  get_results("S");
}
</script>'
};

print "Content-Type: text/html\n\n";
$tt->process('assign_invoices.tt',$Vars);

$dbh->disconnect;
exit;

