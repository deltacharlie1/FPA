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
my $dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");

#  Save the current filter settings

$Sts = $dbh->do("update tempstacks set f1='$FORM{tbselect}',f2='$FORM{tbstart}',f3='$FORM{tbend}' where acct_id='$COOKIE->{ACCT}' and caller='report'");

$Invoices = $dbh->prepare("select cus_id,invoices.id as invid,invinvoiceno,invcusname,invtype,invdesc,date_format(invprintdate,'%d-%b-%y') as printdate,date_format(invduedate,'%d-%b-%y') as duedate,invtotal,invvat,(invtotal+invvat) as invamount,invstatus,(invpaid+invpaidvat) as invpaid,to_days(invprintdate) as printdays,to_days(invduedate) as duedays,cusdefpaymethod from invoices left join customers on (customers.id=cus_id) where invprintdate>=str_to_date('$FORM{tbstart}','%d-%b-%y') and invprintdate<=str_to_date('$FORM{tbend}','%d-%b-%y') and invinvoiceno <> 'unlisted' and invoices.acct_id='$COOKIE->{ACCT}' order by invprintdate");
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

