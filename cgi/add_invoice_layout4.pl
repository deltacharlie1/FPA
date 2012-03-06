#!/usr/bin/perl

$ACCESS_LEVEL = 3;

#  script to add/update customer details

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

use CGI;
use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");
unless ($COOKIE->{NO_ADS}) {
	require "/usr/local/git/fpa/cgi/display_adverts.ph";
	&display_adverts();
}

$Data = new CGI;
%FORM = $Data->Vars;

while (( $Key,$Value) = each %FORM) {

#  Remove any bad characters

	$Value =~ tr/\\//d;
	$Value =~ s/\'/\\\'/g;
        $FORM{$Key} = $Value;

}

@Rows = split(/\n/,$FORM{data});
foreach $Row (@Rows) {
	chomp($Row);

#  Col0 - id, col1 - top, col2 - left, col3 width, col4, height col5 bold

	@Cols = split('-',$Row);

	if ($Cols[5] =~ /bold/i) {
		$Cols[5] = "Y";
	}
	else {
		$Cols[5] = "N";
	}
	$Sts = $dbh->do("update invoice_layout_items set litop='$Cols[1]',lileft='$Cols[2]',liwidth='$Cols[3]',lisize='$Cols[4]',libold='$Cols[5]' where acct_id='$COOKIE->{ACCT}' and link_id=$FORM{id} and lifldcode='$Cols[0]'");

	if ($Cols[0] =~ /a020/i) {
		$Sts = $dbh->do("update invoice_layouts set descwidth='$Cols[3]',descheight='$Cols[4]' where acct_id='$COOKIE->{ACCT}' and id=$FORM{id}");
	}
}

#  Get the last invoice to use as an example

$Invoices = $dbh->prepare("select id from invoices where acct_id='$COOKIE->{ACCT}' and invtype='S' order by id desc limit 1");
$Invoices->execute;
$Invoice = $Invoices->fetchrow_hashref;
$Invoices->finish;

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
        WRAPPER => 'header.tt',
});

$Vars = {
        title => 'Accounts - Invoice Layouts',
        cookie => $COOKIE,
	invid => $Invoice->{id},
        layid => $FORM{id}
};

print "Content-Type: text/html\n\n";
$tt->process('add_invoice_layout4.tt',$Vars);

$dbh->disconnect;
exit;
