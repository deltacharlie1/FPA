#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to display Statement details

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
	$Stmts = $dbh->prepare("select statements.id as stmtid,date_format(staclosedate,'%d-%b-%y') as tdate,stastmtno,staopenbal,staclosebal,stanotxns,accname,accacctno from statements left join accounts on (acc_id=accounts.id) where statements.acct_id='$COOKIE->{ACCT}' and stanotxns<>'-1' order by staclosedate desc");
	$Stmts->execute;
	$FORM{numrows} = $Stmts->rows;
	$FORM{offset} = 0;
	$FORM{rows} = 24;
}

$Stmts = $dbh->prepare("select statements.id as stmtid,date_format(staclosedate,'%d-%b-%y') as tdate,stastmtno,staopenbal,staclosebal,stanotxns,accname,accacctno from statements left join accounts on (acc_id=accounts.id) where statements.acct_id='$COOKIE->{ACCT}' and stanotxns<>'-1' order by staclosedate desc limit $FORM{offset},$FORM{rows}");
$Stmts->execute;

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
        WRAPPER => 'header.tt',
});

$Vars = {
        title => 'Accounts - Statements',
	cookie => $COOKIE,
       numrows => $FORM{numrows},
        offset => $FORM{offset},
        rows => $FORM{rows},

	entries => $Stmts->fetchall_arrayref({}),
        javascript => '<script type="text/javascript">
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

  location.href = "/cgi-bin/fpa/list_txns.pl?numrows=" + numrows + "&offset=" + offset + "&rows=" + rows + "&search=" + srch;
}
</script>'
};

print "Content-Type: text/html\n\n";
$tt->process('list_stmts.tt',$Vars);

$Stmts->finish;
$dbh->disconnect;
exit;

