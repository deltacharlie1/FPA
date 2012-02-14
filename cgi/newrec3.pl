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

require "/usr/local/git/fpa/cgi/process_invoice.ph";
require "/usr/local/git/fpa/cgi/process_purchase.ph";

print "Content-Type:text/plain\n\n";

$Txn_ids = "";
$New_data = "";
$FORM{stmtdata} =~ tr/\r\n//d;
@Txn;

# while ($FORM{stmtdata} =~ s/^.*?(<table.*?droppable.*?>.*?<\/table>)/&Table($1)/oegi) {}

while ($FORM{stmtdata} =~ s/^.*?(<tbody id.*?<\/tbody>.*?<\/tbody>)/&Tbody($1)/oegi) {}

#  Now that we have everything in a table form start processing it

@Rows = split(/\n/,$New_data);
foreach $Row ($Rows) {
	@Cells = split(/\t/,$Row);

	if ($Cells[1] =~ /txn/i) {

#  This is easy, just add the txn id to the txn_ids list

		$Txn_ids .= $Cells[0].",";
	}
	elsif ($Cells[1] =~ /pur/i) {

#  Money Out

		$FORM{id} = '';
		$FORM{invtype} = "P";
		$FORM{cus_id} = $Cells[0];
		$FORM{invprintdate} = $Cells[2];
		$FORM{vatrate} = $Cells[3];
		$FORM{invcoa} = $Cells[4];
		$FORM{invcusname} = $Cells[5];
		$FORM{invdesc} = $Cells[6];
		$FORM{invtotal} = $Cells[7] - $Cells[8];
		$FORM{invvat} = $Cells[8];
		$FORM{invcusregion} = "UK";
		$FORM{txnamount} = $Cells[7];

		&save_purchase();
		&money_out();
		&pay_purchase();
	}
	elsif ($Cells[1] =~ /sal/i) }

#  Money Out

		$FORM{id} = '';
		$FORM{invtype} = "S";
		$FORM{cus_id} = $Cells[0];
		$FORM{invprintdate} = $Cells[2];
		$FORM{vatrate} = $Cells[3];
		$FORM{invcoa} = $Cells[4];
		$FORM{invcusname} = $Cells[5];
		$FORM{invdesc} = $Cells[6];
		$FORM{invtotal} = $Cells[7] - $Cells[8];
		$FORM{invvat} = $Cells[8];
		$FORM{invcusregion} = "UK";
		$FORM{txnamount} = $Cells[7];

		&save_invoice();
		&money_in();
		&pay_invoice();
	}
}

print<<EOD;
Content-Type: text/plain

Account - $FORM{acctype}

$New_data
EOD
$dbh->disconnect;
exit;
sub Tbody {

	my $Tbody = $_[0];
	$#Txn = -1;
#  Extract the first row

	$Tbody =~ /^.*?(<tr.*?>.*?<\/tr>)(.*)$/i;

	$First_row = $1;
	$Rest = $2;

	$First_row =~ s/^.*?(<tr.*?>.*?<\/tr>)/&First_Row($1)/ei;
	@First_row = split(/\t/,$First_row);
print "=============================================================\n";
print "$First_row[2]\n";
print "-------------------------------------------------------------\n";

	 $Rest =~ s/^.*?<tbody>.*?(<tr.*?>.*<\/tr>)/$1/i;
	 while ($Rest =~ s/(<tr.*?>.*?<\/tr>)/&Cell($1)/eig) {}
	foreach (@Txn) { print $_."\n"; }
print "-------------------------------------------------------------\n\n";
}

sub First_Row {
	my $Cell = $_[0];
	$Cell =~ s/.*?<tr.*?>(.*)?<\/tr>/$1/i;
	$Cell =~ s/\s*<td.*?>\s*//ig;
	$Cell =~ s/\s*<\/td>\s*/\t/g;
	$Cell =~ s/\<span.*?<\/span>//i;

#  Get the txnamount

	return $Cell;

}
sub Cell {

	my $Cell = $_[0];
	$Cell =~ s/.*?<tr.*?>(.*)?<\/tr>/$1/i;
	$Cell =~ s/\s*<td.*?>\s*//ig;
	$Cell =~ s/\s*<\/td>\s*/\t/g;
	$Cell =~ s/<img.*?>//g;

	push(@Txn,$Cell);
	return '';
}
