#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to list audit trail entries (mot recent first)

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

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");
unless ($COOKIE->{NO_ADS}) {
	require "/usr/local/git/fpa/cgi/display_adverts.ph";
	&display_adverts();
}


unless ($FORM{rows}) {
	$ATs = $dbh->prepare("select id,cusname,cusaddress,cuspostcode,cusregion,custel,cuscontact,cusbalance,cuscredit,cuslimit,cusdefpaymethod from customers where cusname $SQL and acct_id=? and cussales='Y'");
	$Customers->execute("$COOKIE->{ACCT}");
	$FORM{numrows} = $Customers->rows;
	$FORM{offset} = 0;
	$FORM{rows} = 24;
}
$Customers = $dbh->prepare("select id,cusname,cusaddress,cuspostcode,cusregion,custel,cuscontact,cusbalance,cuscredit,cuslimit,cusdefpaymethod from customers where cusname $SQL and acct_id=? and cussales='Y' order by cusname limit $FORM{offset},$FORM{rows}");
$Customers->execute("$COOKIE->{ACCT}");

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
        WRAPPER => 'header.tt',
});

$Vars = {
        title => 'Accounts - Customers',
	cookie => $COOKIE,
	entries => $Customers->fetchall_arrayref({}),
	numrows => $FORM{numrows},
	offset => $FORM{offset},
	rows => $FORM{rows},
	srch => $FORM{search},
        javascript => '<script language="JavaScript">
function get_amt(cusid,cusname,paymethod) {
  document.getElementById("cusid").value = cusid;
  $("#cusname").html(cusname);

  switch(paymethod) {
    case "1300":
      document.getElementById("pay").options[0].selected = true;
      break;

    case "1310":
      document.getElementById("pay").options[1].selected = true;
      break;

    case "11200":
      document.getElementById("pay").options[2].selected = true;
      break;
  }

  document.getElementById("amtpaid").focus();
  $("#payment").dialog("open");
}
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

  location.href = "/cgi-bin/fpa/list_customers.pl?numrows=" + numrows + "&offset=" + offset + "&rows=" + rows + "&search=" + srch;
}
function check_vat(obj) {
  if (document.getElementById("amtpaid").value.length > 0) {
    if (/^\d+\.?\d?\d?$/.test(document.getElementById("amtpaid").value)) {
      if (obj.value == "Y") {
        if (document.getElementById("amtpaid").value.length < 1) {
          alert("No amount entered");
        }
        else {
          var vat = document.getElementById("amtpaid").value * 17.5 / 117.5;
          document.getElementById("vatpaid").value = vat.toFixed(2);
        }
      }
      else {
        document.getElementById("vatpaid").value = "";
      }
    }
    else {
      alert("Invalid amount entered, must be in the form nn.nn");
    }
  }
}
</script>',
};

print "Content-Type: text/html\n\n";
$tt->process('list_customers.tt',$Vars);

$Customers->finish;
$dbh->disconnect;
exit;

