#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to list invoice templates

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
	$Invoices = $dbh->prepare("select cus_id,id as invid,invcusname,invcuspostcode,invdesc,date_format(invnextinvdate,'%d-%b-%y') as printdate,invrepeatfreq,(invtotal+invvat) as invamount from invoice_templates where acct_id='$COOKIE->{ACCT}' order by invnextinvdate");
        $Invoices->execute;
        $FORM{numrows} = $Invoices->rows;
        $FORM{offset} = 0;
        $FORM{rows} = 24;
}

	$Invoices = $dbh->prepare("select cus_id,id as invid,invcusname,invcuspostcode,invdesc,date_format(invnextinvdate,'%d-%b-%y') as printdate,invrepeatfreq,(invtotal+invvat) as invamount from invoice_templates where acct_id='$COOKIE->{ACCT}' order by invnextinvdate limit $FORM{offset},$FORM{rows}");
$Invoices->execute;

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
        WRAPPER => 'header.tt',
});

$Vars = {
	 ads => $Adverts,
        title => 'Accounts - Invoice Templates',
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

  location.href = "/cgi-bin/fpa/list_templates.pl?numrows=" + numrows + "&offset=" + offset + "&rows=" + rows + "&search=" + srch;
}
</script>',
};

print "Content-Type: text/html\n\n";
$tt->process('list_templates.tt',$Vars);

$Invoices->finish;
$dbh->disconnect;
exit;

