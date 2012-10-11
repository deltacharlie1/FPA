#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to list VAT Returns

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
	$Vatreturns = $dbh->prepare("select id,perquarter,date_format(perstartdate,'%d-%b-%y') as startdate,date_format(perenddate,'%d-%b-%y') as enddate,perbox5,date_format(perduedate,'%d-%b-%y') as perduedate,date_format(percompleted,'%d-%b-%y') as percompleted,date_format(perfiled,'%d-%b-%y') as perfiled,perstatus from vatreturns where acct_id='$COOKIE->{ACCT}' order by perenddate desc");

        $Vatreturns->execute;
        $FORM{numrows} = $Vatreturns->rows;
        $FORM{offset} = 0;
        $FORM{rows} = 24;
}

$Vatreturns = $dbh->prepare("select id,perquarter,date_format(perstartdate,'%d-%b-%y') as startdate,date_format(perenddate,'%d-%b-%y') as enddate,perbox5,date_format(perduedate,'%d-%b-%y') as perduedate,date_format(percompleted,'%d-%b-%y') as percompleted,date_format(perfiled,'%d-%b-%y') as perfiled,perstatus from vatreturns where acct_id='$COOKIE->{ACCT}' order by perenddate desc limit $FORM{offset},$FORM{rows}");
$Vatreturns->execute;

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
        WRAPPER => 'header.tt',
});

$Vars = {
	 ads => $Adverts,
        title => 'Accounts - Vatreturns',
	cookie => $COOKIE,
	vatreturns => $Vatreturns->fetchall_arrayref({}),
	numrows => $FORM{numrows},
	offset => $FORM{offset},
	rows => $FORM{rows},
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
  }

  location.href = "/cgi-bin/fpa/list_vatreturns.pl?numrows=" + numrows + "&offset=" + offset + "&rows=" + rows + "&search=" + srch;
}
</script>'
};

print "Content-Type: text/html\n\n";
$tt->process('list_vatreturns.tt',$Vars);

$Vatreturns->finish;
$dbh->disconnect;
exit;

