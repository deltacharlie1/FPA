#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to list invoices

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

$Buffer = $ENV{QUERY_STRING};

@pairs = split(/&/,$Buffer);

# print "Content-Type: text/plain\n\n";

foreach $pair (@pairs) {

        ($Name, $Value) = split(/=/, $pair);

        $Value =~ tr/+/ /;
        $Value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C",hex($1))/eg;
        $Value =~ tr/\\\'//d;
        $FORM{$Name} = $Value;
# print "$Name = $Value\n";
}
# exit;

$SQL = "";
if ($FORM{invitem}) {
	$SQL .= "invoices.invdesc like '$FORM{invitem}%' and ";
}
if ($FORM{invtype}) {
	$SQL .= "invoices.invtype='$FORM{invtype}' and ";
}

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");
unless ($COOKIE->{NO_ADS}) {
	require "/usr/local/git/fpa/cgi/display_adverts.ph";
	&display_adverts();
}


#  Save the current filter settings

$Sts = $dbh->do("update tempstacks set f1='$FORM{tbselect}',f2='$FORM{tbstart}',f3='$FORM{tbend}',f4='$FORM{tbsort}' where acct_id='$COOKIE->{ACCT}' and caller='report'");

$Invoices = $dbh->prepare("select id as invid,invinvoiceno,invcusname,invtype,invdesc,date_format(invprintdate,'%d-%b-%y') as printdate,invtotal,invvat,(invtotal+invvat) as invamount,invstatus from invoices where $SQL invprintdate>=str_to_date('$FORM{tbstart}','%d-%b-%y') and invprintdate<=str_to_date('$FORM{tbend}','%d-%b-%y') and invinvoiceno <> 'unlisted' and invoices.acct_id='$COOKIE->{ACCT}' order by $FORM{tbsort}");
$Invoices->execute;
$Invoice = $Invoices->fetchall_arrayref({});

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
});

$Vars = {
	cookie => $COOKIE,
	tbstart => $FORM{tbstart},
	tbend => $FORM{tbend},
	numrows => $Invoices->rows,
        invoices => $Invoice
};

print "Content-Type: text/html\n\n";
$tt->process('nom_invoices_results.tt',$Vars);

$Invoices->finish;
$dbh->disconnect;
exit;

