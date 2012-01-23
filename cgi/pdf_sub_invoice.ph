sub pdf_invoice {

use PDF::API2;

my $pdf = PDF::API2->open('/usr/local/git/fpa/htdocs/images/sub_invoice_template.pdf');
my $font = $pdf->corefont('Helvetica');
my $font_bold = $pdf->corefont('Helvetica Bold');

# $Stamp = $pdf_image_png('/usr/local/git/fpa/htdos/images/logo.png');

my $page = $pdf->openpage(1);
# $page->mediabox('A4');

$Inv_desc =~ s/\@ (\d+)\./'@ '.chr(163).$1.'.'/e;

@Line = split(/\n/,$Inv_address);

my $text = $page->text();

$text->font($font_bold,28);
$text->fillcolor("#666666");
$text->translate(298,790);
$text->text_center($Inv_type);
$text->fillcolor("#000000");

$text->font($font,12);

$text->translate(380,625);	#  Invoice No
$text->text($Inv_invoice_no);
$text->translate(380,601);	#  Invoice Date
$text->text($Inv_date);
$text->translate(380,574);	#  Authcode
$text->text($Inv_authcode);

$text->translate(65,625);
foreach (@Line) {
	$text->text(substr($_,0,33));
	$text->cr(-14);
}

$text->translate(70,455);	#  Description
$text->text($Inv_desc);
$text->translate(529,455);	#  Net Amount
$text->text_right($Inv_net);

$text->translate(529,197);
$text->text_right($Inv_net);

$text->translate(529,163);
$text->text_right($Inv_vat);

my $Total = sprintf('%1.2f',$Amt + $Vat);

$text->font($font_bold,14);
$text->translate(531,132);
$text->text_right($Total);


my $g = $page->gfx();

if ($Inv_status =~ /paid/i) {

	my $Stamp_date = $Inv_date;
	$Stamp_date =~ s/(\d+).*?\s(\w\w\w).*(\d\d)$/$1-$2-$3/;

	$img = $pdf->image_png('/usr/local/git/fpa/htdocs/icons/paid2.png');
	$g->image($img,180,270);

	$text->font($font,14);
	$text->transform(-translate => [240,292], -rotate => 24);
	$text->text($Stamp_date);
}
else {
	$img = $pdf->image_png('/usr/local/git/fpa/htdocs/icons/overdue.png');
	$g->image($img,150,250);
}

my $PDF_doc = $pdf->stringify();
$pdf->end;
return ($PDF_doc);
}
1;
