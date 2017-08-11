#!/usr/bin/perl

$ACCESS_LEVEL = 3;

#  script to add/update customer details

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

use CGI;
use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");
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

#  Col0 - id, col1 - top, col2 - left, col3 - width, col4 - height, col5 - bold, col6 - justify, col7 - display Y/N  (col6 is calculated)

	@Col = split('-',$Row);

	$Col[1] =~ s/(.*)\..*$/$1/;

	if ($Col[5] =~ /bold/i) {
		$Col[5] = "Y";
	}
	else {
		$Col[5] = "N";
	}
	if ($Col[1]>=0 && $Col[1]<850 && $Col[2]>=0 && $Col[2]<600) {
		$Col[7] = "Y";
	}
	else {
		$Col[7] = "N";
	}
	$Sts = $dbh->do("update invoice_layout_items set litop='$Col[1]',lileft='$Col[2]',liwidth='$Col[3]',lisize='$Col[4]',libold='$Col[5]',lijust='$Col[6]',lidisplay='$Col[7]' where acct_id='$COOKIE->{ACCT}' and link_id=$FORM{id} and lifldcode='$Col[0]'");
	unless ($Sts > 0) {

#  We need to add a duplicated item, so first get the original

		$Original_fldcode = substr($Col[0],0,4);
		$Items = $dbh->prepare("select lidispname,litable,lisource,lialias from invoice_layout_items where acct_id='$COOKIE->{ACCT}' and link_id=$FORM{id} and lifldcode='$Original_fldcode'");
		$Items->execute;
		$Item = $Items->fetchrow_hashref;
		$Items->finish;

		$Sts = $dbh->do("insert into invoice_layout_items (acct_id,link_id,lifldcode,litop,lileft,liwidth,lisize,libold,lijust,lidisplay,lidispname,litable,lisource,lialias) values ('$COOKIE->{ACCT}',$FORM{id},'$Col[0]','$Col[1]','$Col[2]','$Col[3]','$Col[4]','$Col[5]','$Col[6]','$Col[7]','$Item->{lidispname}','$Item->{litable}','$Item->{lisource}','$Item->{lialias}')");
	}
	if ($Col[0] =~ /a020/i) {
		$Sts = $dbh->do("update invoice_layouts set descwidth='$Col[3]',descheight='$Col[4]' where acct_id='$COOKIE->{ACCT}' and id=$FORM{id}");
	}
	elsif ($Col[0] =~ /a013/i) {
		$Sts = $dbh->do("update invoice_layouts set rmkwidth='$Col[3]',rmkheight='$Col[4]' where acct_id='$COOKIE->{ACCT}' and id=$FORM{id}");
	}
}

#  Get the layout description

$Layouts = $dbh->prepare("select laydesc from invoice_layouts where acct_id='$COOKIE->{ACCT}' and id=$FORM{id}");
$Layouts->execute;
$Layout = $Layouts->fetchrow_hashref;
$Layouts->finish;

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
	 ads => $Adverts,
        title => 'Accounts - Invoice Layouts',
        cookie => $COOKIE,
	invid => $Invoice->{id},
        layid => $FORM{id},
        laydesc => $Layout->{laydesc}
};

print "Content-Type: text/html\n\n";
$tt->process('add_invoice_layout4.tt',$Vars);

$dbh->disconnect;
exit;
