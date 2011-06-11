#!/usr/bin/perl
use PDF::API2;

#$pdf = PDF::API2->new;

$pdf = PDF::API2->open('testit.pdf');
#$pdf = PDF::API2->new();

$font = $pdf->corefont('Helvetica',1);
$page = $pdf->openpage(1);
$page->mediabox('A4');

$text = $page->text();
$text->font($font,12);

use CGI;
$Data = new CGI;
%FORM = $Data->Vars;

while (( $Key,$Value) = each %FORM) {

#  Remove any bad characters

        $Value =~ s/\%2b/\+/ig;
        $Value =~ tr/\\//d;
        $Value =~ s/\'/\\\'/g;

	if ($Value =~ /:\d+/) {
		@Data = split(/\:/,$Value);
		$text->translate($Data[1],832 - $Data[2]);
		$text->text($Data[0]);
	}
}

print "Content-Type: application/pdf\n";
print "Content-Disposition: inline; filename=invoice_$Invoice_no.pdf\n\n";

print $pdf->stringify();
$pdf->end;


exit;
