sub pdf_invoice {

$Invoice_id = $_[0];
$Use_stamp = $_[1];

use GD;
use PDF::API2;
use PDF::TextBlock;
use PDF::TextBlock::Font;

#  Get the company name

($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});
$Companies= $dbh->prepare("select comname,comaddress,compostcode,comtel,comemail,comregno,comvatno,comlogo from companies where reg_id=$Reg_id and id=$Com_id");
$Companies->execute;
@Company = $Companies->fetchrow;
$Companies->finish;

$Accts = $dbh->prepare("select accname,accsort,accacctno from accounts where acct_id='$COOKIE->{ACCT}' and acctype='1200'");
$Accts->execute;
$Acct = $Accts->fetchrow_hashref;
$Accts->finish;

chomp($Company[1]);
$Disp_address = "$Company[0]\n$Company[1]\n$Company[2]\n\nTel: $Company[3]\nEmail: $Company[4]";
$Disp_address =~ tr/\r//d;

#  Get the VAT percentage rates

$Vats = $dbh->prepare("select vatcode,vatpercent from vatrates");
$Vats->execute;
$Vatrate = $Vats->fetchall_hashref('vatcode');
$Vats->finish;

#  Now get the invoice data

$Invoices = $dbh->prepare("select invinvoiceno,date_format(invprintdate,'%d %b %Y'),date_format(invduedate,'%d %b %Y'),invcusterms,invcusref,invcusname,invcusaddr,invcuspostcode,invcuscontact,invitems,invremarks,date_format(curdate(),'%d %b %Y'),invstatus,invtype,invourref,invcistotal from invoices where id=$Invoice_id and acct_id='$COOKIE->{ACCT}'");
$Invoices->execute;
@Invoice = $Invoices->fetchrow;
$Invoices->finish;

$Invtype = "";
if ($Invoice[12] =~ /Draft/i) {
	$Invtype = "DRAFT ";
}
if ($Invoice[13] =~ /^C/) {
	$Invtype .= "CREDIT NOTE";
	$Invtext = "Credit Note";
}
elsif ($Invoice[12] =~ /Quote/i) {
	$Invtype = "QUOTATION";
	$Invtext = "Quote";
}
else {
	$Invtype .= "INVOICE";
	$Invtext = "Invoice";
}

if ($Invoice[3] == "0") {
	$Invoice[3] = "Due Now";
}
elsif ($Invoice[3] =~ /^\d+$/) {
	$Invoice[3] .= " Days";
}

$Ref_text = "Your";
$Ourref_addition = 0;
if ($Invoice[4] && $Invoice[14]) {
	$Ourref_addition = 29;
}
elsif ($Invoice[14]) {
	$Ref_text = "Our";
	$Invoice[4] = $Invoice[14];
}

###  Set Global PDF parameters  ###

# my ($page, $text, $g, $endw, $Ypos, $tb, $Net, $Vat, $Total);

$page = "";
$text = "";
$g = "";
$endw = "";
$Ypos = "";
$tb = "";
$Net = "";
$Vat = "";
$Total = "";

$pdf = PDF::API2->new;
$font = $pdf->corefont('Helvetica');
$font_bold = $pdf->corefont('Helvetica Bold');
$font_bold_italic = $pdf->corefont('Helvetica BoldOblique');
$font_italic = $pdf->corefont('Helvetica Oblique');

if ($COOKIE->{PT_LOGO} && $Company[7]) {
# $Img =~ s/([\\\"\'])/\\$1/g;
	$Company[7] =~ s/\\\'/\'/g;
	$Company[7] =~ s/\\\"/\"/g;
#	$Company[7] =~ s/\\\\/\\/g;

#  Make the logo greyscale

	my $gdimg = GD::Image->new($Company[7]);
	my $i = 0;
	my $t = $gdimg->colorsTotal;

	while($i < $t) {
		my( @c ) = $gdimg->rgb( $i );
		my $g = .30 * $c[0] + .59 * $c[1] + .11 * $c[2];
		$gdimg->colorDeallocate($i);
		$gdimg->colorAllocate( $g, $g, $g );
		$i++;
	}

	$logo = $pdf->image_gd($gdimg);

}

#  Get overdue icon

$Stamp = $pdf->image_png('overdue.png');

#  Set out the first page

&set_new_page;

$Invoice[9] =~ s/^.*?<tr>//is;		#  Remove everything up to the first table row
$Invoice[9] =~ s/^.*?<tr>//is;		#  Then again to remove all headers
$Invoice[9] =~ s/<tr.*?>//gis;		#  Remove all row start tags

@Row = split(/\<\/tr\>/i,$Invoice[9]);
for $Row (@Row) {
	$Row =~ s/^.*?<td.*?>//is;
        $Row =~ s/<td.*?>//gis;
        @Cell = split(/\<\/td\>/i,$Row);

	if ($Cell[0]) {

#  remove any date/increment brackets

		$Cell[0] =~ s/\[(\%|\+|\-) //g;
		$Cell[0] =~ s/ (\%|\+|\-)\]//g;

#  Convert ampersands

		$Cell[0] =~ s/\&amp;/\&/ig;
		$Cell[0] =~ s/<br\/>/\n/ig;
		$Cell[3] =~ s/<br\/>//ig;
		$Cell[5] =~ s/<br\/>//ig;

		if ($COOKIE->{VAT} =~ /N/i) {
			$text->transform( -translate => [471,$Ypos]);
			$text->text_right($Cell[2]);
			$text->transform( -translate => [544,$Ypos]);
			$text->text_right($Cell[4]);
		}
		else {
			$text->transform( -translate => [348,$Ypos]);
			$text->text_right($Cell[2]);
			$text->transform( -translate => [425,$Ypos]);
			$text->text_right($Cell[3]);
			$text->transform( -translate => [471,$Ypos]);
			$text->text_right($Cell[4]);
			$text->transform( -translate => [544,$Ypos]);
			$text->text_right($Cell[5]);
		}

		$tb->y($Ypos);
		$tb->text($Cell[0]);
		($endw, $Ypos) = $tb->apply();

		$Ypos -= 25;
		$Net += $Cell[3];
		$Vat += $Cell[5];
		$Total += $Cell[3] + $Cell[5];

		if ($Ypos < 200) {
			&set_new_page;
		}
	}
}
#exit;

#  Put in any remarks

if ($Invoice[15] && ! $Invoice[10]) {
	$Pound = pack("H2","A3");
	$Invoice[15] += $Vat;
	$Invoice[10] = "Total due for payment = ".$Pound.$Invoice[15];

}
if ($Invoice[10]) {
	$Ypos = 139;
	$tb->y($Ypos);
	$tb->text($Invoice[10]);
	($endw, $Ypos) = $tb->apply();
}

#  Finally, enter the totals

$text->lead('28');
$text->transform( -translate => [544,137]);

if ($COOKIE->{VAT} =~ /N/i) {
	$text->font($font_bold,12);
	$text->text_right(sprintf("%1.2f",$Total));
}
else {
	$text->text_right(sprintf("%1.2f",$Net));
	$text->cr();
	$text->text_right(sprintf("%1.2f",$Vat));
	$text->cr();
	$text->font($font_bold,12);
	$text->text_right(sprintf("%1.2f",$Total));
}

#  See if we need an overdue stamp

if ($Invoice[12] =~ /overdue/i && $Use_stamp =~ /Y/i) {
	$g->image($Stamp,200,260);
}

my $PDF_doc = $pdf->stringify();
$pdf->end;
return ($PDF_doc,$Invoice[0]);

}

sub set_new_page {

###  Form wide parameters  ###

$page = $pdf->page();
$page->mediabox('A4');
$g = $page->gfx();

#  Logo

if ($logo) {
	$g->image($logo,43,709);
}

####################    Draw all lines and blocks   ##########################
#  Invoice Type border

$g->fillcolor("#eeeeee");
$g->strokecolor("#000000");
$g->rectxy(43,773,258,799);		#  Invoice Type box
$g->rectxy(43,440,552,469);		#  Line Item Headings
$g->fillstroke();		#  Needed at this point, else all rectangles are shaded

#  Customer Address Block Rectangle

$g->rectxy(43,550,284,669);

#  Invoice conditions etc block

$g->rectxy(312,525-$Ourref_addition,552,669);
$g->move(312,640);
$g->line(552,640);
$g->move(312,609);
$g->line(552,609);
$g->move(312,580);
$g->line(552,580);
$g->move(312,551);
$g->line(552,551);
if ($Ourref_addition) {
	$g->move(312,522);
	$g->line(552,522);
}
$g->move(425,669);
$g->line(425,525-$Ourref_addition);

#  Line Item Block

$g->rectxy(43,159,552,469);
$g->move(479,469);
$g->line(479,159);
$g->move(433,469);
$g->line(433,159);

unless ($COOKIE->{VAT} =~ /N/i) {
	$g->move(356,469);
	$g->line(356,159);
	$g->move(312,469);
	$g->line(312,159);
}

#  Totals block

if ($COOKIE->{VAT} =~ /N/i) {
	$g->rectxy(312,131,552,159);
	$g->move(479,159);
	$g->line(479,131);
}
else {
	$g->rectxy(312,75,552,159);
	$g->move(312,131);
	$g->line(552,131);
	$g->move(312,103);
	$g->line(552,103);
	$g->move(433,159);
	$g->line(433,75);
}

$g->stroke;

###############    Standard Text   ###################

#  Invoice type text

$g->fillcolor("#000000");
$text = $page->text();

unless ($COOKIE->{PT_LOGO}) {
        $text->transform( -translate =>[90,760]);
        $text->font($font_italic, 8);
        $text->lead(12);
        $text->text("Printed using");
        $text->font($font_bold_italic,8);
        $text->text(" FreePlus Accounts");
        $text->cr();
        $text->font($font_italic, 8);
        $text->text("(www.freeplusaccounts.co.uk)");
}

$text->font($font_bold,11);
$text->transform( -translate => [320,647]);
$text->text($Invtext." No");
$text->transform( -translate => [320,618]);
$text->text($Invtext." Date");
$text->transform( -translate => [320,589]);
$text->text("Due By Date");
$text->transform( -translate => [320,560]);
$text->text("Terms");
$text->transform( -translate => [320,531]);
$text->text("$Ref_text Reference");
if ($Ourref_addition) {
	$text->transform( -translate => [320,502]);
	$text->text("Our Reference");
}
$text->transform( -translate => [51,447]);
$text->text("Description");

if ($COOKIE->{VAT} =~ /N/i) {
	$text->transform( -translate => [437,447]);
	$text->text("Qty");

	$text->transform( -translate => [482,447]);
	$text->text("Total");
}
else {
	$text->transform( -translate => [322,447]);
	$text->text("Qty");

	$text->transform( -translate => [361,447]);
	$text->text("Net Amount");

	$text->transform( -translate => [437,447]);
	$text->text("VAT %");

	$text->transform( -translate => [482,447]);
	$text->text("VAT Amount");
}

if ($COOKIE->{VAT} =~ /N/i) {
	$text->transform( -translate => [320,137]);
	$text->text("Total");
}
else {
	$text->transform( -translate => [320,137]);
	$text->text("Net Total");

	$text->transform( -translate => [320,109]);
	$text->text("VAT Total");

	$text->transform( -translate => [320,81]);
	$text->text($Invtext." Total");
}

############   Variable Data   ####################

#  Invoice Type

$text->transform( -translate => [151,779]);
$text->font($font_bold, 20);
$text->lead(24);
$text->text_center($Invtype);
$Line_len = 0;

$text->font($font, 12);
$text->lead(14);

@Line = split(/\n/,$Disp_address);
foreach (@Line) {
	$width = $text->advancewidth($_);
	if ($width > $Line_len) {
		$Line_len = $width;
	}
}
$Col = 532 - int($Line_len);

$text->transform( -translate => [$Col,792]);
foreach (@Line) {
	$text->text($_);
	$text->cr();
}

if ($Company[6] && $COOKIE->{VAT} !~ /N/i) {
	$text->transform( -translate => [350,507-$Ourref_addition]);
	$text->font($font_bold, 10);
	$text->text("VAT Registration No: ");
	$text->font($font, 10);
	$text->text($Company[6]);
}

if ($Company[5]) {
	$text->font($font_bold, 10);
	$Line_len = $text->advancewidth("Company Registration No: ");
	$text->font($font, 10);
	$Line_len += $text->advancewidth($Company[5]);
	$text->transform( -translate => [297 - int($Line_len / 2),54]);
	$text->font($font_bold, 10);
	$text->text("Company Registration No: ");
	$text->font($font, 10);
	$text->text($Company[5]);
}

if ($Acct->{accname}) {
	$text->font($font_bold, 10);
	$Line_len = $text->advancewidth("Bank: ");
	$Line_len += $text->advancewidth(" Sort Code: ");
	$Line_len += $text->advancewidth(" Account: ");
	$text->font($font, 10);
	$Line_len += $text->advancewidth($Acct->{accname});
	$Line_len += $text->advancewidth($Acct->{accsort});
	$Line_len += $text->advancewidth($Acct->{accacctno});
	$text->transform( -translate => [297 - int($Line_len / 2),38]);
	$text->font($font_bold, 10);
	$text->text("Bank: ");
	$text->font($font, 10);
	$text->text($Acct->{accname});
	$text->font($font_bold, 10);
	$text->text(" Sort Code: ");
	$text->font($font, 10);
	$text->text($Acct->{accsort});
	$text->font($font_bold, 10);
	$text->text(" Account: ");
	$text->font($font, 10);
	$text->text($Acct->{accacctno});
}

#  Customer Address

$text->font($font, 12);
$text->lead(14);
$text->transform( -translate => [51,653]);
$text->text($Invoice[5]);
$text->cr();

@Line = split(/\n/,$Invoice[6]);
foreach (@Line) {
	$text->text($_);
	$text->cr();
}
$text->text($Invoice[7]);
$text->cr();
$text->cr();
$text->text("FAO: " . $Invoice[8]);

#  Invoice header details

$text->lead(29);
$text->transform( -translate => [433,647]);
$text->text($Invoice[0]);
$text->cr();
if ($Invoice[1]) {
	$text->text($Invoice[1]);
}
else {
	$text->text($Invoice[11]);
}
$text->cr();
$text->text($Invoice[2]);
$text->cr();
$text->text($Invoice[3]);
$text->cr();
$text->text($Invoice[4]);
if ($Ourref_addition) {
	$text->cr();
	$text->text($Invoice[14]);
}

#  Set the line item block settings

$Ypos = 425;
$text->font($font,10);

#  Now do the line items - set up the text block fiexed parameters

$tb = PDF::TextBlock->new({
   pdf   => $pdf,
   page  => $page,
   fonts => {
      default => PDF::TextBlock::Font->new({
         pdf       => $pdf,
         font      => $pdf->corefont( 'Helvetica' ),
         size      => 10,
      }),
   },
   x     => 51,
   w     => 254,
   h     => 266,
   align => 'left',
});
}
1;
