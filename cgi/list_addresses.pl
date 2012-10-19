#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to display Contact Details (for eventual updating)

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
# print FILE "$Name = $Value\n";
}

if ($FORM{search}) {
	if ($FORM{search} =~ /9/) {
		$SQL = "< 'A'";
	}
	else {
		$SQL = "like '$FORM{search}%'";
	}
}
else {
	$SQL = ">= ''";
}

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");

unless ($FORM{rows}) {
	$Customers = $dbh->prepare("select id,cusname,cusaddress,cuspostcode,cusregion,custel,cuscontact,cusemail,cussales,cussupplier from customers where cusname $SQL and acct_id=?");
	$Customers->execute("$COOKIE->{ACCT}");
	$FORM{numrows} = $Customers->rows;
	$FORM{offset} = 0;
	$FORM{rows} = 24;
}

$Customers = $dbh->prepare("select id,cusname,cusaddress,cuspostcode,cusregion,custel,cuscontact,cusemail,cussales,cussupplier from customers where cusname $SQL and acct_id=? order by cusname limit $FORM{offset},$FORM{rows}");
$Customers->execute("$COOKIE->{ACCT}");

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
        WRAPPER => 'header.tt',
});

$Vars = {
	 ads => $Adverts,
        title => 'Accounts - Customers',
	cookie => $COOKIE,
	entries => $Customers->fetchall_arrayref({}),
	numrows => $FORM{numrows},
	offset => $FORM{offset},
	rows => $FORM{rows},
	srch => $FORM{search},
        javascript => '<style type="text/css">
.suppressed { color:#999999; }
</style>
<script language="JavaScript">
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

  location.href = "/cgi-bin/fpa/list_addresses.pl?numrows=" + numrows + "&offset=" + offset + "&rows=" + rows + "&search=" + srch;
}
</script>',
};

print "Content-Type: text/html\n\n";
$tt->process('list_addresses.tt',$Vars);

$Customers->finish;
$dbh->disconnect;
exit;

