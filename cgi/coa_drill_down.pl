#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to display Transaction details

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

use DBI;
my $dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");

$Buffer = $ENV{QUERY_STRING};

$FORM{numrows} = "";

@pairs = split(/&/,$Buffer);

foreach $pair (@pairs) {

        ($Name, $Value) = split(/=/, $pair);

        $Value =~ tr/+/ /;
        $Value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C",hex($1))/eg;
        $Value =~ tr/\\\'//d;
        $FORM{$Name} = $Value;
}

unless ($FORM{tbstart}) {
	$FORM{tbstart} = "01-Jan-05";
}
unless ($FORM{tbend}) {
	$FORM{tbend} = "31-Dec-50";
}

unless ($FORM{numrows}) {
	$Nominals = $dbh->prepare("select count(*),sum(nomamount),coadesc,coatype from nominals left join coas on (nominals.nomcode=coas.coanominalcode and nominals.acct_id=coas.acct_id) where nominals.acct_id='$COOKIE->{ACCT}' and nomcode='$FORM{filter}' and nomdate>=str_to_date('$FORM{tbstart}','%d-%b-%y') and nomdate<=str_to_date('$FORM{tbend}','%d-%b-%y')");
	$Nominals->execute;
	($FORM{numrows},$FORM{pagebalance},$FORM{pagetitle},$Coatype) = $Nominals->fetchrow;
	$FORM{offset} = 0;
	$FORM{rows} = 24;
}

$Nominals = $dbh->prepare("select nominals.link_id as linkid,nominals.nomtype,nominals.nomcode,nominals.nomamount as amount,date_format(nominals.nomdate,'%d-%b-%y') as printdate,invinvoiceno,concat(invcusname,' (',invdesc,')') as invcusname,txntxnno,concat(txncusname,' (',txnremarks,')') as txncusname from nominals left join invoices on (nominals.link_id=invoices.id and nominals.acct_id=invoices.acct_id),nominals a left join transactions on (a.link_id=transactions.id and a.acct_id=transactions.acct_id) where nominals.id=a.id and nominals.acct_id=a.acct_id and nominals.nomcode='$FORM{filter}' and nominals.nomdate>=str_to_date('$FORM{tbstart}','%d-%b-%y') and nominals.nomdate<=str_to_date('$FORM{tbend}','%d-%b-%y') and nominals.acct_id='$COOKIE->{ACCT}' order by nominals.nomdate limit $FORM{offset},$FORM{rows}");
$Nominals->execute;

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
        WRAPPER => 'header.tt',
});

$Vars = {
       	title => 'Accounts - ' . $FORM{nomtitle},
	cookie => $COOKIE,
	pagetitle => $FORM{pagetitle},
	pagebalance => $FORM{pagebalance},
       	numrows => $FORM{numrows},
        offset => $FORM{offset},
       	rows => $FORM{rows},
	filter => $FORM{filter},
	coatype => $Coatype,
	entries => $Nominals->fetchall_arrayref({}),
        javascript => '<script type="text/javascript">
function redisplay(action) {

  pagetitle = escape("'.$FORM{pagetitle}.'"),
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

  location.href = "/cgi-bin/fpa/coa_drill_down.pl?filter=" + filter + "&numrows=" + numrows + "&offset=" + offset + "&rows=" + rows + "&pagetitle=" + pagetitle + "&pagebalance=\''.$FORM{pagebalance}.'\'";
}
</script>'
};

$Nominals->finish;
print "Content-Type: text/html\n\n";
$tt->process('list_coa_inv.tt',$Vars);

$dbh->disconnect;
exit;

