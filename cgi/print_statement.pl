#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to display a statement 

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

$Cus_id = $ENV{QUERY_STRING};

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");
unless ($COOKIE->{NO_ADS}) {
	require "/usr/local/git/fpa/cgi/display_adverts.ph";
	&display_adverts();
}


$Customers = $dbh->prepare("select id,cuscontact,cusemail,cusstmtmsg,date_format(now(),'%M') as stmtdate from customers where id=$Cus_id and acct_id='$COOKIE->{ACCT}'");
$Customers->execute;
$Customer = $Customers->fetchrow_hashref;

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
        WRAPPER => 'header.tt',
});

#  Get the statement date - current month if after 7th, else previous month

@Date = ("January","February","March","April","May","June","July","August","September","October","November","December");

@Today = localtime(time);

if ($Today[3] < 8) {
	$Today[4]--;
	if ($Today[4] < 0) { $Today[4] = 11; }
}

$Vars = {
        title => 'Accounts - Customers',
	cookie => $COOKIE,
	cus => $Customer,
	stmtdate => $Date[$Today[4]],
        javascript => '<script type="text/javascript" src="/js/jquery-form.js"></script> 
<script type="text/javascript">
var responseText = "";
var errfocus = "";
$(document).ready(function(){
  var options = {
    beforeSubmit: validate,
    success: showResponse
  };
  $("#form1").ajaxForm(options);
});
function showResponse(responseText, statusText) {
  if (/OK/i.test(responseText)) {
    var href = responseText.split("-");
    alert(href[1]);
    location.href = "/cgi-bin/fpa/" + href[2];
  }
  else {
    document.getElementById("dialog").innerHTML = responseText;
    $("#dialog").dialog("open");
  }
}
function validate(formData,jqForm,options) {
  return validate_form("#form1");
}
</script>',
};

print "Content-Type: text/html\n\n";
$tt->process('print_statement.tt',$Vars);

$Customers->finish;
$dbh->disconnect;
exit;

