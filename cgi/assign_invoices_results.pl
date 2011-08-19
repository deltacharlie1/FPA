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

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");
unless ($COOKIE->{NO_ADS}) {
	require "/usr/local/git/fpa/cgi/display_adverts.ph";
	&display_adverts();
}


#  Construct the SQL filter

$SQL = "";

if ($FORM{invcusname}) {
	$SQL .= "invcusname like '$FORM{invcusname}%' and ";
}
$SQL .= "invoices.acct_id='$COOKIE->{ACCT}'";

#  Now see if wwe are executing a new query (action = -1) or a continuation of an exisitng one

$Invoices = $dbh->prepare("select invoices.id as invid,cus_id,invtype,invinvoiceno,invcusname,date_format(invprintdate,'%d-%b-%y') as printdate,invdesc,invtotal+invvat as printtotal,invstatus from invoices left join customers on (cus_id=customers.id and invoices.acct_id=customers.acct_id) where customers.cusname='Unlisted' and $SQL");
$Invoices->execute;

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
});

$Vars = {
	cookie => $COOKIE,
	invoices => $Invoices->fetchall_arrayref({})
};

print "Content-Type: text/html\n\n";
$tt->process('assign_invoices_results.tt',$Vars);

$Invoices->finish;
$dbh->disconnect;
exit;

