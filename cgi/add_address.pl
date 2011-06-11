#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to display Contact Details (for eventual updating)

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

$Cus_type = $ENV{QUERY_STRING};

use DBI;
my $dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");

if ($Cus_type =~ /^\d+$/) {
	$Customers = $dbh->prepare("select id,cusname,cusaddress,cuspostcode,cusregion,custel,cuscontact,cusemail,custerms,cusdefpo,cusbank,cussortcode,cusacctno,cusdefpaymethod,cusbalance,cussales,cussupplier,cusremarks,cuslimit,cusdefcoa,cusdefvatrate,cusemailmsg,cusstmtmsg,cusautostmts from customers where acct_id=? and id=?");
	$Customers->execute("$COOKIE->{ACCT}",$ENV{QUERY_STRING});
	$Customer = $Customers->fetchrow_hashref;
	$Customers->finish;
	$Cus_type = "S";
	if ($Customer->{cussales} =~ /Y/i) {
		$Cus_type = "C";
	}
}
else {

#  This is a new customer so get the default email and statement messages

	($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});
	$Companies = $dbh->prepare("select comemailmsg,comstmtmsg from companies where reg_id=$Reg_id and id=$Com_id");
	$Companies->execute;
	($Customer->{cusemailmsg},$Customer->{cusstmtmsg}) = $Companies->fetchrow;
	$Companies->finish;
}

$Coas = $dbh->prepare("select coanominalcode,coadesc from coas where coatype='Expenses' and acct_id='$COOKIE->{ACCT}'");
$Coas->execute;
$Coa = $Coas->fetchall_arrayref({});
$Coas->finish;

$Customer->{cusregion} = $Customer->{cusregion} || 'UK';	#  Set the default for empty customer
$Customer->{cusdefcoa} = $Customer->{cusdefcoa} || '5000';	#  Set the default for empty customer

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
        WRAPPER => 'header.tt',
});

$Vars = {
        title => 'Accounts - Customer Details',
	cookie => $COOKIE,
	focus => 'cusname',
	custype => $Cus_type,
	cus => $Customer,
	coas => $Coa,
        javascript => '<script type="text/javascript" src="/js/jquery-form.js"></script> 
<script type="text/javascript">
var responseText = "";
var errfocus = "";
$(document).ready(function(){
  $("#cusdefvatrate").val("'.$Customer->{cusdefvatrate}.'");
  var options = {
    beforeSubmit: validate,
    success: showResponse
  };
  $("#form1").ajaxForm(options);
});
function showResponse(responseText, statusText) {
  if (/OK/i.test(responseText)) {
    var href = responseText.split("-");
    location.href = "/cgi-bin/fpa/" + href[1];
  }
  else {
    document.getElementById("dialog").innerHTML = responseText;
    $("#dialog").dialog("open");
  }
}
function validate(formData,jqForm,options) {
  return validate_form("#form1");
}
function setfocus() {
  eval("document.getElementById(\'" + errfocus + "\').focus();");
}
function confirm_delete() {
  if (confirm("Confirm Delete?")) {
    document.getElementById("ignore_action").value = "Delete";
    document.form1.submit();
  }
}
</script>',
};

print "Content-Type: text/html\n\n";
$tt->process('add_address.tt',$Vars);

$dbh->disconnect;
exit;

