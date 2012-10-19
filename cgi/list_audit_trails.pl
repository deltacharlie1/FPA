#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to display audit trail 

%Cookie = {};

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

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");

unless ($FORM{rows}) {
	$ATs = $dbh->prepare("select link_id,audtype,audaction,date_format(audstamp,'%d-%b-%y %H:%i') as audstamp,audtext,auduser from audit_trails where acct_id='$COOKIE->{ACCT}' order by audstamp desc");
	$ATs->execute;
	$FORM{numrows} = $ATs->rows;
	$FORM{offset} = 0;
	$FORM{rows} = 24;
}

$ATs = $dbh->prepare("select link_id,audtype,audaction,date_format(audstamp,'%d-%b-%y %H:%i') as audtime,audtext,auduser from audit_trails where acct_id='$COOKIE->{ACCT}' order by audstamp desc limit $FORM{offset},$FORM{rows}");
$ATs->execute;

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
        WRAPPER => 'header.tt',
});

$Vars = {
	 ads => $Adverts,
        title => 'Accounts - Audit Trail',
	cookie => $COOKIE,
       numrows => $FORM{numrows},
        offset => $FORM{offset},
        rows => $FORM{rows},

	entries => $ATs->fetchall_arrayref({}),
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

  location.href = "/cgi-bin/fpa/list_audit_trails.pl?numrows=" + numrows + "&offset=" + offset + "&rows=" + rows + "&search=" + srch;
}
</script>'
};

print "Content-Type: text/html\n\n";

$tt->process('list_audit_trails.tt',$Vars);

$ATs->finish;
$dbh->disconnect;
exit;

