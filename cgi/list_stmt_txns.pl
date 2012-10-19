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

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");

$Stmts = $dbh->prepare("select statements.id as id,stastmtno,staopenbal,staclosebal,date_format(staopendate,'%d-%b-%y') as staopendate,date_format(staclosedate,'%d-%b-%y') as staclosedate,accname,accsort,accacctno from statements left join accounts on (acc_id=accounts.id) where statements.acct_id='$COOKIE->{ACCT}' and statements.id=$FORM{filter}");
$Stmts->execute;
$Stmt = $Stmts->fetchrow_hashref;
$Stmts->finish;

unless ($FORM{rows}) {
	$Txns = $dbh->prepare("select date_format(txndate,'%d-%b-%y') as tdate,concat(txncusname,' (',txnremarks,')') as txncusname,txnamount from transactions where stmt_id=$FORM{filter} and acct_id=? order by txndate");
	$Txns->execute("$COOKIE->{ACCT}");
	$FORM{numrows} = $Txns->rows;
	$FORM{offset} = 0;
	$FORM{rows} = 24;
}

$Txns = $dbh->prepare("select date_format(txndate,'%d-%b-%y') as tdate,concat(txncusname,' (',txnremarks,')') as txncusname,txnamount from transactions where stmt_id=$FORM{filter} and acct_id=? order by txndate limit $FORM{offset},$FORM{rows}");
$Txns->execute("$COOKIE->{ACCT}");

#  see if we have any statment attachments

$Images = $dbh->prepare("select id,imgthumb from images where acct_id='$COOKIE->{ACCT}' and link_id=$FORM{filter} limit 1");
$Images->execute;
unless ($Images->rows > 0) {
	$Uploadify = sprintf<<EOD;
\$(document).ready(function(){
  \$("#stfile").uploadify ({
    "uploader"       : "/js/uploadify.swf",
    "script"         : "/cgi-bin/fpa/uploadify.pl",
    "cancelImg"      : "/js/cancel.png",
    "buttonText"     : "Save Statement",
    "onComplete"     : function(a,b,c,d,e) { window.location.reload(true); },
    "fileExt"        : "*.pdf;*.jpg;*.png",
    "fileDesc"       : "PDF or Image Files (*.pdf,*.jpg,*.png)",
    "scriptData"     : {"cookie" : "$COOKIE->{COOKIE}", "doc_type" : "STMT" ,"doc_rec" : "$Stmt->{id}" },
    "sizeLimit"      : $COOKIE->{UPLDS},
    "expressInstall" : "/js/expressInstall.swf",
    "auto"           : true
  });
});
EOD
}
$Image = $Images->fetchrow_hashref;
$Images->finish;

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
	attach => $Image,
	entries => $Txns->fetchall_arrayref({}),
	stmt => $Stmt,
        javascript => '<script type="text/javascript">
'.$Uploadify.'function sorttable() {
  var cls = new Array();
  cls[0] = "even";
  cls[1] = "odd";
  var cls_ndx = 0;

  var body = document.getElementById("sorttable");
  var noRows = body.rows.length;
  for (var i=noRows - 1;i>=0;i--) {
    cls_ndx++;
    var El = body.removeChild(body.rows[i]);
    El.className = cls[cls_ndx%2];
    body.appendChild(El);
  }
}
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

  location.href = "/cgi-bin/fpa/list_txns.pl?filter=" + filter + "&numrows=" + numrows + "&offset=" + offset + "&rows=" + rows + "&search=" + srch;
}
</script>'
};

print "Content-Type: text/html\n\n";
$tt->process('list_stmt_txns.tt',$Vars);

$Txns->finish;
$dbh->disconnect;
exit;

