#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to display Transaction details

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

use DBI;
my $dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");

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

#  First get details of this nominal code

$Coas = $dbh->prepare("select coadesc,coabalance from coas where acct_id='$COOKIE->{ACCT}' and coanominalcode='$FORM{filter}'");
$Coas->execute;
@Coa = $Coas->fetchrow;
$Coas->finish;

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
        WRAPPER => 'header.tt',
});

if ($FORM{filter}  =~ /2100/) {
	$Invtype = "invtype in ('S','C')";
}
else {
	$Invtype = "invtype in ('P','R')";
}

unless ($FORM{rows}) {
	$Txns = $dbh->prepare("select id,invinvoiceno,date_format(invprintdate,'%d-%b-%y') as tdate,concat(invcusname,' (',invdesc,')') as invcusname,invvat from invoices where acct_id='$COOKIE->{ACCT}' and $Invtype order by invprintdate desc");
	$Txns->execute;
	$FORM{numrows} = $Txns->rows;
	$FORM{offset} = 0;
	$FORM{rows} = 24;
}

$Txns = $dbh->prepare("select id,invinvoiceno,date_format(invprintdate,'%d-%b-%y') as tdate,concat(invcusname,' (',invdesc,')') as invcusname,invvat from invoices where acct_id='$COOKIE->{ACCT}' and $Invtype order by invprintdate desc limit $FORM{offset},$FORM{rows}");
$Txns->execute;

$Vars = {
       	title => 'Accounts - ' . $Coa[0],
       	filter => $FORM{filter},
	cookie => $COOKIE,
	pagetitle => $Coa[0],
	pagebalance => $Coa[1],
       	numrows => $FORM{numrows},
        offset => $FORM{offset},
       	rows => $FORM{rows},
	entries => $Txns->fetchall_arrayref({}),
        javascript => '<script type="text/javascript">
function redisplay(action) {
  numrows = ' . $FORM{numrows} . ';
  offset = ' . $FORM{offset} . ';
  rows = ' . $FORM{rows} . ';
  srch = "' . $FORM{search} . '";
  filter = "' . $FORM{filter} . '";

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

  location.href = "/cgi-bin/fpa/coa_drill_down.pl?filter=" + filter + "&numrows=" + numrows + "&offset=" + offset + "&rows=" + rows + "&search=" + srch;
}
</script>'
};

$Txns->finish;
print "Content-Type: text/html\n\n";
$tt->process('list_coa_vats.tt',$Vars);

$dbh->disconnect;
exit;

