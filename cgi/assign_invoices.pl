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
	 ads => $Adverts,
        title => 'Accounts - Invoice Analysis',
	cookie => $COOKIE,
	focus => 'invcusname',
        startdate => $Start_date,
        enddate => $End_date,
        javascript => '<script type="text/javascript"> 
$(document).ready(function(){
  $("#cussrch").autocomplete({
    minLength: 0,
    delay: 50,
    source: function (request,response) {
      request.type = document.getElementById("custype").value;
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
  $.get("/cgi-bin/fpa/assign_invoices_results.pl",$("form#form1").serialize() ,function(data) {
    $("#results").html(data);
  });
}
function redisplay(action) {
  get_results("S");
}
function assign_invoices() {
  Errs = "";
  if (document.getElementById("cusname").value.length < 1) {
    Errs = Errs + "<li>You have not selected an Assign-to Customer\/Supplier<\/li>\n";
  }
  None_Checked = true;
  $(".cassign").each(function() {
    if (this.checked) {
      None_Checked = false;
    }
  });
  if (None_Checked) {
    Errs = Errs + "<li>You have not selected any Invoices to re-assign<\/li>\n";
  }
  if (Errs.length > 0) {
    $("#dialog").html("You have the following errors:-\n<ol>" + Errs + "<\/ol>\nPlease correct and resubmit");
    $("#dialog").dialog("open");
  }
  else {
    $.post("/cgi-bin/fpa/assign_invoices2.pl", $("#form1").serialize(),function(data) {
      if ( ! /^OK/.test(data)) {
        alert(data);
      }
      if (document.getElementById("custype").value == "Supplier") {
        location.href = "/cgi-bin/fpa/list_supplier_purchases.pl?" + document.getElementById("cusname").value
      }
      else {
        location.href = "/cgi-bin/fpa/list_customer_invoices.pl?" + document.getElementById("cusname").value
      }
    },"text");
  }
}
</script>'
};

print "Content-Type: text/html\n\n";
$tt->process('assign_invoices.tt',$Vars);

$dbh->disconnect;
exit;

