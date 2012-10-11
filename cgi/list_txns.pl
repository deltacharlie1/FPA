#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to display Transaction details

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

if ($FORM{filter} && $FORM{filter} !~ /All/i) {
	$Filter = " txnmethod='$FORM{filter}'";
}
else {
	$Filter = "txntxntype in ('income','expense','transfer','vat','bank')";
}

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");
unless ($COOKIE->{NO_ADS}) {
	require "/usr/local/git/fpa/cgi/display_adverts.ph";
	&display_adverts();
}


unless ($FORM{rows}) {
	$Txns = $dbh->prepare("select date_format(txndate,'%d-%b-%y') as tdate,concat(txncusname,' (',txnremarks,')') as txncusname,txnamount,coadesc,txntxnno from transactions left join coas on (txnmethod=coanominalcode) where $Filter and transactions.acct_id='$COOKIE->{ACCT}' and coas.acct_id='$COOKIE->{ACCT}' order by txndate desc,txntxnno desc");
	$Txns->execute;
	$FORM{numrows} = $Txns->rows;
	$FORM{offset} = 0;
	$FORM{rows} = 24;
}

$Txns = $dbh->prepare("select date_format(txndate,'%d-%b-%y') as tdate,concat(txncusname,' (',txnremarks,')') as txncusname,txnamount,coadesc,txntxnno from transactions left join coas on (txnmethod=coanominalcode) where $Filter and transactions.acct_id='$COOKIE->{ACCT}' and coas.acct_id='$COOKIE->{ACCT}' order by txndate desc,txntxnno desc limit $FORM{offset},$FORM{rows}");
$Txns->execute;

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
        WRAPPER => 'header.tt',
});

$Vars = {
	 ads => $Adverts,
        title => 'Accounts - Transactions',
	cookie => $COOKIE,
       numrows => $FORM{numrows},
        offset => $FORM{offset},
        rows => $FORM{rows},
	filter => $FORM{filter},

	entries => $Txns->fetchall_arrayref({}),
        javascript => '<script type="text/javascript">
function redisplay(action) {

  numrows = ' . $FORM{numrows} . ';
  offset = ' . $FORM{offset} . ';
  rows = ' . $FORM{rows} . ';
  filter = "All";

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
  }

  location.href = "/cgi-bin/fpa/list_txns.pl?filter=" + filter + "&numrows=" + numrows + "&offset=" + offset + "&rows=" + rows;
}
</script>'
};

print "Content-Type: text/html\n\n";
$tt->process('list_txns.tt',$Vars);

$Txns->finish;
$dbh->disconnect;
exit;

