#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to reconcile an account

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

$Acctype = $ENV{QUERY_STRING};

use CGI;
use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");
unless ($COOKIE->{NO_ADS}) {
	require "/usr/local/git/fpa/cgi/display_adverts.ph";
	&display_adverts();
}

$Data = new CGI;
%FORM = $Data->Vars;

# print "Content-Type: text/plain\n\n";

while (( $Key,$Value) = each %FORM) {

#  Remove any bad characters

	$Value =~ tr/\\//d;
	$Value =~ s/\'/\\\'/g;
        $FORM{$Key} = $Value;
}

#  Check to see if we have an exisitng spreadsheet saved

unless ($FORM{stmt}) {
	$TSs = $dbh->prepare("select f1,f2,f3 from tempstacks where acct_id='$COOKIE->{ACCT}' and caller='reconciliation'");
	$TSs->execute;
	@TS = $TSs->fetchrow;
	$TSs->finish;

	if ($TS[0]) {
		$FORM{stmt} = $TS[0];
		$FORM{stmtno} = $TS[1];
	}
}

$FORM{stmt} =~ s/\\\'/\'/g;	#  strip out any exisitng escapes
$FORM{stmt} =~ s/\'/\\\'/g;

$Sts = $dbh->do("update tempstacks set f1='$FORM{stmt}',f2='$FORM{stmtno}' where acct_id='$COOKIE->{ACCT}' and caller='reconciliation'");

$Accts = $dbh->prepare("select accounts.id,accounts.acctype,accname,accacctno,stastmtno,staclosebal,date_format(staclosedate,'%d-%b-%y') as staclosedate from accounts left join statements on (accounts.id=acc_id) where accounts.acct_id='$COOKIE->{ACCT}' and acctype='1200' order by statements.id desc limit 1");
$Accts->execute;
$Acct = $Accts->fetchrow_hashref;
$Accts->finish;

$Stmt = [];
$FORM{stmt} =~ tr/\r//d;
@Rows = split(/\n/,$FORM{stmt});
foreach $Row (@Rows) {
	chomp($Row);
	next if ($Row =~ /Date.*Description/i);
	@Cell = split(/\t/,$Row);
	if ($Cell[3] =~ /^\d/) {
		$Cell[4] = 0-$Cell[3];
	}
	$Entry = {};
	$Entry->{date} = $Cell[0];
	$Entry->{desc} = $Cell[2];
	$Entry->{amt} = $Cell[4];
	$Entry->{balance} = $Cell[5];

	if ($Acct->{accname} =~ /HSBC/i) {
		push(@Stmt,$Entry);
	}
	else {
		unshift(@Stmt,$Entry);
	}
}

#  Calculate the opening balance

$Acct->{newopen} = @Stmt[0]->{balance} - @Stmt[0]->{amt} || 0;
$Acct->{newclose} = @Stmt[$#Stmt]->{balance} || 0;

$TSs = $dbh->prepare("select f1,f2,f3 from tempstacks where acct_id='$COOKIE->{ACCT}' and caller='reconciliation'");
$TSs->execute;
$TS = $TSs->fetchrow_hashref;
$TSs->finish;

#  Get all unpaid invoices

$Invoices = $dbh->prepare("select id,invtype,date_format(invprintdate,'%d-%b-%y') as printdate,invinvoiceno,invcusname,invdesc,(invtotal+invvat-invpaid-invpaidvat) as amtdue from invoices where acct_id='$COOKIE->{ACCT}' and invstatuscode>2 order by invprintdate");
$Invoices->execute;
$Invoice = $Invoices->fetchall_arrayref({});

$Txns = $dbh->prepare("select id,txntxntype,date_format(txndate,'%d-%b-%y') as tdate,txncusname,txnremarks,txnamount from transactions where txnselected<>'F' and txnmethod='1200' and acct_id='$COOKIE->{ACCT}' order by txndate");
$Txns->execute;

#  Check to see if there are any Filed VAT returns awaiting reconciliation

$Vats = $dbh->prepare("select id,perquarter,perbox5 from vatreturns where acct_id='$COOKIE->{ACCT}' and perstatus='Filed' order by perstartdate limit 1");
$Vats->execute;

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
        WRAPPER => 'header.tt',
});

$Vars = {
        title => 'Accounts - Reconciliations',
	cookie => $COOKIE,
	acct => $Acct,
	invoices => $Invoice,		# s->fetchall_arrayref({}),
	txns => $Txns->fetchall_arrayref({}),
	vat => $Vats->fetchall_arrayref({}),
	stmt => \@Stmt,
	stack => $TS,
	javascript => '<script type="text/javascript">
var errfocus;
$(document).ready(function(){
  $(".draggable").draggable({
	helper: "clone"
  });
  $(".droppable").droppable({
	accept: ".draggable",
	drop: function(event,ui) {
		$( this ).find( ".placeholder").remove();
		$("<tr></tr>").html( ui.draggable.html()+"<td onclick=\"revert(\'"+ui.draggable.attr("id")+"\',$(this),\'"+$(this).attr("id")+"\');\"><img src=\'/icons/delete.png\' width=\'12\' height=\'12\' alt=\'Delete\'/></td>" ).appendTo( this );
		ui.draggable.draggable( "option", "revert", false );
                var diff = document.getElementById("stmtdiff").innerHTML;
                diff = (diff * 1) - ($(this).find(":nth-child(7)").last().text() * 1);
		document.getElementById("stmtdiff").innerHTML = diff.toFixed(2);
                diff = document.getElementById("p"+$(this).attr("id")).innerHTML;
                diff = (diff * 1) - ($(this).find(":nth-child(7)").last().text() * 1);
		document.getElementById("p"+$(this).attr("id")).innerHTML = diff.toFixed(2);
		ui.draggable.draggable("disable");
		return false;
	}
  });
});
function revert(id,el,dropid) {
  var diff = document.getElementById("stmtdiff").innerHTML;
  diff = (diff * 1) + (el.parent().find(":nth-child(7)").last().text() * 1);
  document.getElementById("stmtdiff").innerHTML = diff.toFixed(2);
  diff = (el.parent().find(":nth-child(7)").last().text() * 1) + (document.getElementById("p"+dropid).innerHTML * 1);
  document.getElementById("p"+dropid).innerHTML = diff.toFixed(2);
  $("#"+id).draggable(\'enable\');
  if (el.parent().parent().children().length < 2) {
    el.parent().replaceWith("<tr class=\'placeholder\'><td colspan=\'4\'></td></tr>");
  }
  else {
    el.parent().remove();
  }
}
</script>'
};

print "Content-Type: text/html\n\n";

$tt->process('newrec2.tt',$Vars);

$Invoices->finish;
$Txns->finish;
$Vats->finish;
$dbh->disconnect;
exit;

