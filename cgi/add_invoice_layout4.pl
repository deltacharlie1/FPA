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

#  Col0 - id, col1 - top, col2 - left, col3 width, col4, height

	@Cols = split('-',$Row);

	$Sts = $dbh->do("update invoice_layout_items set litop='$Cols[1]',lileft='$Cols[2]',liwidth='$Cols[3]' where acct_id='$COOKIE->{ACCT}' and link_id=$FORM{id} and lifldcode='$Cols[0]'");

	if ($Cols[0] =~ /a020/i) {
		$Sts = $dbh->do("update invoice_layouts set descwidth='$Cols[3]',descheight='$Cols[4]' where acct_id='$COOKIE->{ACCT}' and id=$FORM{id}");
	}
}

print<<EOD;
Content-Type: text/html
Status: 301
Location: /cgi-bin/fpa/print_inv_layout.pl?$FORM{id}

EOD
$dbh->disconnect;
exit;
