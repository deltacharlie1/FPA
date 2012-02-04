#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to update Company Details

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

#  Processing for the following types of input row:-

#  inv - invoice not yet marked as paid - so call process_invoice 
#  txn - transaction already entered - so just store id for linking to statement
#  pur - this is a new money out - process_purchase
#  sal - this is a new money in - process_invoice


# warn "$FORM{stmtdata}\n";

$New_data = "";
$FORM{stmtdata} =~ tr/\r\n//d;

while ($FORM{stmtdata} =~ s/^.*?(<table.*?droppable.*?>.*?<\/table>)/&Table($1)/oegi) {}

print<<EOD;
Content-Type: text/plain

Account - $FORM{acctype}

$New_data
EOD
$dbh->disconnect;
exit;

sub Table {

	my $Row = $_[0];

	while ($Row =~ s/^.*?(<tr.*?>.*?<\/tr>)/&Row($1)/egi) {}
	return '';
}
sub Row {
	my $Cell = $_[0];
	$Cell =~ s/.*?<tr.*?>(.*)?<\/tr>/$1/i;
	$Cell =~ s/\s*<td.*?>\s*//ig;
	$Cell =~ s/\s*<\/td>\s*/\t/g;
	$Cell =~ s/<img.*?>//g;
	$New_data .= $Cell."\n\n";
	return '';
}
