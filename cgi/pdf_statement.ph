sub pdf_statement {

my $Cus_id = $_[0];

use GD;
use PDF::API2;

#  Get the company name

($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});
$Companies= $dbh->prepare("select comname,comaddress,compostcode,comtel,comemail,comregno,comvatno,comlogo,date_format(curdate(),'%D %M %Y'),datediff(compt_logo,now()) from companies where reg_id=$Reg_id and id=$Com_id");
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

#  Get the customer details

$Customers = $dbh->prepare("select cusname,cusaddress,cuspostcode,cuscontact,custerms from customers where acct_id='$COOKIE->{ACCT}' and id=$Cus_id");
$Customers->execute;
@Customer = $Customers->fetchrow;
$Customers->finish;

#  Now get the invoice data

$Invoices = $dbh->prepare("select invinvoiceno,date_format(invprintdate,'%d-%b-%y'),to_days(curdate()) - to_days(invduedate),invcusterms,invtotal-invpaid,invvat - invpaidvat,invdesc from invoices where invtype='S' and invstatuscode > 2 and cus_id=$Cus_id and acct_id='$COOKIE->{ACCT}' order by invprintdate");

$Invoices->execute;

###  Set Global PDF parameters  ###

# my ($page, $text, $g, $endw, $Ypos, $tb, $Net, $Vat, $Total);

$pdf = PDF::API2->new;
$font = $pdf->corefont('Helvetica');
$font_bold = $pdf->corefont('Helvetica Bold');
$font_italic = $pdf->corefont('Helvetica Oblique');
$font_bold_italic = $pdf->corefont('Helvetica BoldOblique');
if (($COOKIE->{PLAN} > 3 || $Company[9] > 0) && $Company[7]) {
# $Img =~ s/([\\\"\'])/\\$1/g;
        use MIME::Base64;
        $Company[7] = decode_base64($Company[7]);

        open IMG,"<",\$Company[7];
        $logo = $pdf->image_jpeg(\*IMG);
}

#  Set out the first page

&set_new_page;

$Tot =  0;
$Overdue0 = 0;
$Overdue1 = 0;
$Overdue2 = 0;
$Overdue3 = 0;
$Overdue4 = 0;

while (@Invoice = $Invoices->fetchrow) {

	if (length($Invoice[6]) > 30) {
		$Invoice[6] = substr($Invoice[6],0,27) . "...";
	}

	my $Amt = sprintf("%1.2f",$Invoice[4] + $Invoice[5]);
	$Tot += $Amt;
	if ($Invoice[2] < 1) {
		$Overdue0 += $Amt;
	}
	elsif ($Invoice[2] < 31) {
		$Overdue1 += $Amt;
	}
	elsif ($Invoice[2] < 61) {
		$Overdue2 += $Amt;
	}
	elsif ($Invoice[2] < 91) {
		$Overdue3 += $Amt;
	}
	else {
		$Overdue4 += $Amt;
	}

	$text->transform( -translate => [51,$Ypos]);
	$text->text($Invoice[1]);
	$text->transform( -translate => [114,$Ypos]);
	$text->text($Invoice[0]);
	$text->transform( -translate => [188,$Ypos]);
	$text->text($Invoice[6]);
	if ($COOKIE->{VAT} !~ /N/i) {
		$text->transform( -translate => [406,$Ypos]);
		$text->text_right($Invoice[4]);
		$text->transform( -translate => [456,$Ypos]);
		$text->text_right($Invoice[5]);
	}
	$text->transform( -translate => [544,$Ypos]);
	$text->text_right($Amt);

	$Ypos -= 20;
	$Net += $Cell[3];
	$Vat += $Cell[5];
	$Total += $Cell[3] + $Cell[5];

	if ($Ypos < 200) {
		&set_new_page;
	}
}

#  Now print the statement header details (date & amount) and the overdue amounts

$text->font($font_bold,14);
$text->transform( -translate => [476,647]);
$text->text_center($Company[8]);
$text->transform( -translate => [476,618]);
$text->text_center(chr(163). sprintf("%1.2f",$Tot));

#  Now the overdues

$text->transform( -translate => [93,85]);
$text->text_center(sprintf("%1.2f",$Overdue0));

if ($Overdue1) {
	$text->transform( -translate => [195,85]);
	$text->text_center(sprintf("%1.2f",$Overdue1));
}
if ($Overdue2) {
	$text->transform( -translate => [297,85]);
	$text->text_center(sprintf("%1.2f",$Overdue2));
}
if ($Overdue3) {
	$text->transform( -translate => [398,85]);
	$text->text_center(sprintf("%1.2f",$Overdue3));
}
if ($Overdue4) {
	$text->transform( -translate => [499,85]);
	$text->text_center(sprintf("%1.2f",$Overdue4));
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
$Ypos =  495;

#  Logo

if ($logo) {
	$g->image($logo,43,709);
}

####################    Draw all lines and blocks   ##########################
#  Invoice Type border

$g->fillcolor("#eeeeee");
$g->strokecolor("#000000");
$g->rectxy(43,773,284,799);		#  Invoice Type box
$g->rectxy(43,105,552,140);		#  overdue Headings
$g->rectxy(43,511,552,540);		#  Line Item Headings
$g->fillstroke();		#  Needed at this point, else all rectangles are shaded

#  Customer Address Block Rectangle

$g->rectxy(43,550,284,669);

#  Statement details

$g->rectxy(300,608,552,669);
$g->move(400,669);
$g->line(400,608);
$g->move(300,638);
$g->line(552,638);

#  Line Item Block

$g->rectxy(43,159,552,540);
$g->move(106,540);
$g->line(106,159);
$g->move(180,540);
$g->line(180,159);

if ($COOKIE->{VAT} !~ /N/i) {
	$g->move(346,540);
	$g->line(346,159);
	$g->move(416,540);
	$g->line(416,159);
}
$g->move(464,540);
$g->line(464,159);

#  Totals block

$g->rectxy(43,75,552,140);
$g->move(144,140);
$g->line(144,75);
$g->move(245,140);
$g->line(245,75);
$g->move(346,140);
$g->line(346,75);
$g->move(447,140);
$g->line(447,75);

$g->stroke;

###############    Standard Text   ###################

#  Invoice type text

$g->fillcolor("#000000");
$text = $page->text();

unless ($COOKIE->{PT_LOGO}) {		#  include the freeplus text
        $text->transform( -translate =>[100,742]);
        $text->font($font_italic, 8);
        $text->lead(12);
        $text->text("Produced using");
        $text->font($font_bold_italic,8);
        $text->text(" FreePlus Accounts");
        $text->cr();
        $text->font($font_italic, 8);
        $text->text("Free Accounting from");
        $text->cr();
        $text->text("www.freeplusaccounts.co.uk");
}

$text->font($font_bold,11);
$text->transform( -translate => [310,647]);
$text->text("Statement Date");
$text->transform( -translate => [310,618]);
$text->text("Total Due");

$text->transform( -translate => [51,518]);
$text->text("Date");
$text->transform( -translate => [114,518]);
$text->text("Invoice No");
$text->transform( -translate => [188,518]);
$text->text("Description");

unless ($COOKIE->{VAT} =~ /N/i) {
	$text->transform( -translate => [354,518]);
	$text->text("Net");

	$text->transform( -translate => [424,518]);
	$text->text("VAT");
}
$text->transform( -translate => [472,518]);
$text->text("Amount Due");

$text->lead(14);
$text->transform( -translate => [93,117]);
$text->text_center("Within Terms");
$text->transform( -translate => [195,124]);
$text->text_center("Overdue by");
$text->cr();
$text->text_center("1 - 30 Days");
$text->transform( -translate => [297,124]);
$text->text_center("Overdue by");
$text->cr();
$text->text_center("31 - 60 Days");
$text->transform( -translate => [398,124]);
$text->text_center("Overdue by");
$text->cr();
$text->text_center("61 - 90 Days");
$text->transform( -translate => [499,124]);
$text->text_center("Overdue by");
$text->cr();
$text->text_center("More than 90 Days");


############   Variable Data   ####################

#  Invoice Type

#  Calculate the month


@Date = ("January","February","March","April","May","June","July","August","September","October","November","December");

@Today = localtime(time);

if ($Today[3] < 8) {
        $Today[4]--;
        if ($Today[4] < 0) { $Today[4] = 11; }
}

$text->transform( -translate => [163,779]);
$text->font($font_bold, 20);
$text->lead(24);
$text->text_center($Date[$Today[4]].' Statement');
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
	$text->transform( -translate => [350,589]);
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
	$text->transform( -translate => [297 - int($Line_len / 2),50]);
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
$text->text($Customer[0]);
$text->cr();

@Line = split(/\n/,$Customer[1]);
foreach (@Line) {
	$text->text($_);
	$text->cr();
}
$text->text($Customer[2]);
$text->cr();
$text->cr();
$text->text("FAO: " . $Customer[3]);

$text->font($font,10);
}
1;
