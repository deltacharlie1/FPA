#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to list purchase invoices

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

$Buffer = $ENV{QUERY_STRING};

@pairs = split(/&/,$Buffer);

foreach $pair (@pairs) {

        ($Name, $Value) = split(/=/, $pair);

        $Value =~ tr/+/ /;
        $Value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C",hex($1))/eg;
        $Value =~ tr/\\\'//d;
        $FORM{$Name} = $Value;
}

if ($FORM{listorder} =~ /O/i) {
	$Order = "invstatuscode desc,invduedate desc,invprintdate desc";
}
else {
	$Order = "invinvoiceno desc";
}

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");
unless ($COOKIE->{NO_ADS}) {
	require "/usr/local/git/fpa/cgi/display_adverts.ph";
	&display_adverts();
}


unless ($FORM{rows}) {
	$Invoices = $dbh->prepare("select cus_id,invoices.id as invid,invinvoiceno,invcusname,invtype,invdesc,date_format(invprintdate,'%d-%b-%y') as printdate,date_format(invduedate,'%d-%b-%y') as duedate,0 - (invtotal+invvat) as invamount,invstatus,0 - (invpaid+invpaidvat) as invpaid,to_days(invprintdate) as printdays,to_days(invduedate) as duedays,cusdefpaymethod,invcusref from invoices left join customers on (customers.id=cus_id) where invinvoiceno <> 'unlisted' and invtype='P' and invoices.acct_id='$COOKIE->{ACCT}' order by $Order");
        $Invoices->execute;
        $FORM{numrows} = $Invoices->rows;
        $FORM{offset} = 0;
        $FORM{rows} = 24;
}

$Invoices = $dbh->prepare("select cus_id,invoices.id as invid,invinvoiceno,invcusname,invtype,invdesc,date_format(invprintdate,'%d-%b-%y') as printdate,date_format(invduedate,'%d-%b-%y') as duedate,0 - (invtotal+invvat) as invamount,invstatus,0 - (invpaid+invpaidvat) as invpaid,to_days(invprintdate) as printdays,to_days(invduedate) as duedays,cusdefpaymethod,invcusref from invoices left join customers on (customers.id=cus_id) where invinvoiceno <> 'unlisted' and invtype='P' and invoices.acct_id='$COOKIE->{ACCT}' order by $Order limit $FORM{offset},$FORM{rows}");
$Invoices->execute;

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
        WRAPPER => 'header.tt',
});

$Vars = {
        title => 'Accounts - Invoices',
	cookie => $COOKIE,
	invoices => $Invoices->fetchall_arrayref({}),
	numrows => $FORM{numrows},
	offset => $FORM{offset},
	rows => $FORM{rows},
        javascript => '<script type="text/javascript">
var responseText = "";
var errfocus = "";
$(document).ready(function(){
  $(function() {
    $("#i_invprintdate").datepicker();
    $("#invpayment").dialog({
      bgiframe: true,
      autoOpen: false,
      position: [200,100],
      height: 350,
      width: 400,
      modal: true,
      buttons: {
        "Record Payment": function() {
          if (validate_form("#payform")) {
            if (parseFloat($("#i_txnamount").value) > parseFloat(document.getElementById("amtowed").html())) {
              if (confirm("Paid Amount greater than Owed Amount, balance will be held on Account")) {
                $.post("/cgi-bin/fpa/make_purchase_payment.pl",$("form#payform").serialize() ,function(data) {
                $(this).dialog("close");
                window.location.reload(true); },"text");
              }
            }
            else {
              $.post("/cgi-bin/fpa/make_purchase_payment.pl",$("form#payform").serialize(),function(data) {
              $(this).dialog("close");
              window.location.reload(true); },"text");
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

  numrows = ' . $FORM{numrows} . ';
  offset = ' . $FORM{offset} . ';
  rows = ' . $FORM{rows} . ';
  srch = "' . $FORM{search} . '";

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

  location.href = "/cgi-bin/fpa/list_purchases.pl?listorder=' . $List_order . '&numrows=" + numrows + "&offset=" + offset + "&rows=" + rows + "&search=" + srch;
}
function get_amt(amtinvid,amtinvno,amtamt,paymethod,amtcusid,paycoa) {
  document.getElementById("i_id").value = amtinvid;
  document.getElementById("i_cus_id").value = amtcusid;
  $("#amtinvno").html(amtinvno);
  $("#amtowed").html(parseFloat(amtamt).toFixed(2));
  document.getElementById("i_txnamount").value = parseFloat(amtamt).toFixed(2);
  document.getElementById("i_invremarks").value = "Purchase Invoice " + amtinvno;
  $("#pay").val(paymethod);
  $("#i_invcoa").val(paycoa);
  document.getElementById("i_txnamount").focus();
  $("#invpayment").dialog("open");
}
</script>',
};

print "Content-Type: text/html\n\n";
$tt->process('list_purchases.tt',$Vars);

$Invoices->finish;
$dbh->disconnect;
exit;

