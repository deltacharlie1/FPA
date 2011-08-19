#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to display Contact Details (for eventual updating)

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");
unless ($COOKIE->{NO_ADS}) {
	require "/usr/local/git/fpa/cgi/display_adverts.ph";
	&display_adverts();
}


$Customers = $dbh->prepare("select id,cusname,cusaddress,cuspostcode,cusregion,custel,cuscontact,cusemail,custerms,cusbalance,cuscredit,cuslimit,cusdefpaymethod from customers where id=? and acct_id=?");
$Customers->execute($ENV{QUERY_STRING},"$COOKIE->{ACCT}");

$Invoices = $dbh->prepare("select invoices.id as invid,invinvoiceno,invtype,invdesc,date_format(invprintdate,'%d-%b-%y') as printdate,date_format(invduedate,'%d-%b-%y') as duedate,(invtotal+invvat) as invamount,invstatus,(invpaid+invpaidvat) as invpaid,to_days(invprintdate) as printdays,to_days(invduedate) as duedays,invstatuscode,date_format(max(itdate),'%d-%b-%y') as itdate from invoices left join inv_txns on (inv_txns.inv_id=invoices.id and inv_txns.acct_id=invoices.acct_id) where invinvoiceno <> 'unlisted' and invtype in ('S','C') and cus_id=? and invoices.acct_id=? group by invoices.id order by invstatuscode desc,invprintdate desc limit 0,24");
$Invoices->execute($ENV{QUERY_STRING},"$COOKIE->{ACCT}");
$Numrows = $Invoices->rows;
$Rows = 24;
$Offset = 0;

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
        WRAPPER => 'header.tt',
});

$Vars = {
        title => 'Accounts - Customers',
	cookie => $COOKIE,
	cus => $Customers->fetchrow_hashref,
	invoices => $Invoices->fetchall_arrayref({}),
	numrows => $Numrows,
	offset => $Offset,
	rows => $Rows,
        javascript => '<script language="JavaScript">
var responseText = "";
var errfocus = "";
$(document).ready(function(){
  $("#i_invprintdate").datepicker();
  $(function() {
    $("#invpayment").dialog({
      bgiframe: true,
      autoOpen: false,
      position: [200,100],
      height: 350,
      width: 400,
      modal: true,
      buttons: {
        "Record Payment": function() {
          if(validate_form("#payform")) {
            if (parseFloat(document.getElementById("i_txnamount").value) > parseFloat(document.getElementById("amtowed").innerHTML)) {
              if (confirm("Paid Amount greater than Owed Amount, balance will be held on Account")) {
                $.post("/cgi-bin/fpa/receive_invoice_payment.pl", $("#payform").serialize(),function(data) {
                if ( ! /^OK/.test(data)) {
                  alert(data);
                }
                window.location.reload(true);
                },"text");
                $(this).dialog("close");
              }
            }
            else {
              $.post("/cgi-bin/fpa/receive_invoice_payment.pl", $("form#payform").serialize(),function(data) {
                if ( ! /^OK/.test(data)) {
                  alert(data);
                }
                window.location.reload(true);
              },"text");
              $(this).dialog("close");
            }
          }
        },
        Cancel: function() {
          $(this).dialog("close");
        }
      }
  });
});
});
function redisplay(action) {

  numrows = ' . $Numrows . ';
  offset = ' . $Offset . ';
  rows = ' . $Rows . ';
  srch = "' . $Search . '";

  if (document.getElementById("goto").value.length > 0) {
    offset = (document.getElementById("goto").value - 2) * rows;
    if (offset >= numrows) {
      offset = numrows - (numrows % rows);
    }
  }

  switch(action) {

    case "first":
      offset = 0;
      break;

    case "back":
      offset - rows < 0 ? offset = 0 : offset = offset - rows;
      break;

    case "next":
      offset + rows < numrows ? offset = offset + rows : offset = offset;
      break;

    case "last":
      offset = numrows - (numrows % rows);
      break;

    case "all":
      numrows = "";
      offset = "";
      rows = "";
      srch = "";
      break;

    case "9":
      numrows = "";
      offset = "";
      rows = "";
      srch = "9";
      break;

    default:
      numrows = "";
      offset = "";
      rows = "";
      srch = action;
      break;
  }

  location.href = "/cgi-bin/fpa/list_customer_invoices.pl?numrows=" + numrows + "&offset=" + offset + "&rows=" + rows + "&search=" + srch;
}
function get_amt(amtinvid,amtinvno,amtamt) {
  document.getElementById("i_id").value = amtinvid;
  document.getElementById("amtinvno").innerHTML = amtinvno;
  document.getElementById("amtowed").innerHTML = parseFloat(amtamt).toFixed(2);
  document.getElementById("i_txnamount").value = parseFloat(amtamt).toFixed(2);
  document.getElementById("i_invdesc").value = "Invoice " + amtinvno;
//  document.getElementById("i_txnamount").focus();
  $("#invpayment").dialog("open");
}
</script>',
};

print "Content-Type: text/html\n\n";
$tt->process('list_customer_invoices.tt',$Vars);

$Customers->finish;
$Invoices->finish;
$dbh->disconnect;
exit;

