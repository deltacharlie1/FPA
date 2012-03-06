sub pdf_invoice {

$Inv_id = $_[0];
$Use_stamp = $_[1];
$Layout_id = $_[2];

#  get the layout

$Layouts = $dbh->prepare("select * from invoice_layouts where acct_id='$COOKIE->{ACCT}' and id=$Layout_id");
$Layouts->execute;
$Layout = $Layouts->fetchrow_hashref;
$Layouts->finish;

$LIs = $dbh->prepare("select * from invoice_layout_items where acct_id='$COOKIE->{ACCT}' and lidisplay='Y' and link_id=$Layout_id");
$LIs->execute;
$LIT = $LIs->fetchall_arrayref({});
$LIs->finish;

#  Build the select

foreach $LI (@$LIT) {

	if ($LI->{litable} =~ /companies/i) {
		$C_sel .= $LI->{lisource}." as ".$LI->{lialias}.",";
	}
	elsif ($LI->{litable} =~ /accounts/i) {
		$A_sel .= $LI->{lisource}." as ".$LI->{lialias}.",";
	}
	elsif ($LI->{litable} =~ /invoices/i) {
		$I_sel .= $LI->{lisource}." as ".$LI->{lialias}.",";
	}
	elsif ($LI->{litable} =~ /items/i  && $I_sel !~ /invitems/i) {
		$I_sel .= 'invitems,';
	}
}

chop($C_sel);
chop($A_sel);
chop($I_sel);

($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});

if ($C_sel) {
	$Companies = $dbh->prepare("select $C_sel from companies where reg_id=$Reg_id and id=$Com_id");
	$Companies->execute;
	$companies = $Companies->fetchrow_hashref;
	$Companies->finish;
}
if ($A_sel) {
	$Accts = $dbh->prepare("select $A_sel from accounts where acct_id='$COOKIE->{ACCT}' and acctype='1200'");
	$Accts->execute;
	$accounts = $Accts->fetchrow_hashref;
	$Accts->finish;
}
if ($I_sel) {
	$I_sel .= ",invstatus";
	$Invoices = $dbh->prepare("select $I_sel from invoices where acct_id='$COOKIE->{ACCT}' and id=$Inv_id");
	$Invoices->execute;
	$invoices = $Invoices->fetchrow_hashref;
	$Invoices->finish;
}
$dbh->disconnect;

#  Now go through and split out the header and item items

foreach $LI (@$LIT) {
	if ($LI->{litable} =~ /items/i) {
		push(@Items, $LI);
	}
	elsif ($LI->{litable} =~ /calc/i) {
		push(@Calc,$LI);
	}
	else {
		push(@Header,$LI);
	}
}

use GD;
use PDF::API2;
use PDF::TextBlock;
use PDF::TextBlock::Font;

if ($Invoice->{invstatus} =~ /Draft/i) {
	$Invoice->{invtype} = "DRAFT INVOICE";
}
if ($Invoice->{invtype} =~ /^C/) {
	$Invoice->{invtype} = "CREDIT NOTE";
}
elsif ($Invoice->{invstatus} =~ /Quote/i) {
	$Invoice->{invtype} = "QUOTATION";
}
else {
	$Invoice->{invtype} = "INVOICE";
}

if ($Invoice[3] == "0") {
	$Invoice[3] = "Due Now";
}
elsif ($Invoice[3] =~ /^\d+$/) {
	$Invoice[3] .= " Days";
}

$page = "";
$text = "";
$g = "";
$endw = "";
$Ypos = "";
$tb = "";
$Net = "";
$Vat = "";
$Total = "";

$pdf = PDF::API2->open($Layout->{layfile});
$page = $pdf->openpage(1);
$font = $pdf->corefont('Helvetica');
$font_bold = $pdf->corefont('Helvetica Bold');

$Stamp = $pdf->image_png('overdue.png');
$Testonly = $pdf->image_png('/usr/local/git/fpa/htdocs/icons/testonly.png');

#  Set out the first page

&set_new_page;

$invoices->{invitems} =~ s/^.*?<tr>//is;		#  Remove everything up to the first table row
$invoices->{invitems} =~ s/^.*?<tr>//is;		#  Then again to remove all headers
$invoices->{invitems}=~ s/<tr.*?>//gis;			#  Remove all row start tags

@Row = split(/\<\/tr\>/i,$invoices->{invitems});
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

		foreach $Item (@Items) {
			$Item->{lisize} = '10';
			if ($Item->{libold} =~ /Y/i) {
				$text->font($font_bold,$Item->{lisize} );
			}
			else {
				$text->font($font, $Item->{lisize});
			}
			$text->lead($Item->{lisize} + 2);
			if ($Item->{lifldcode} =~ /a020/) {
				$tb->y($Ypos);
				$tb->text($Cell[0]);
				($endw, $New_Ypos) = $tb->apply();
			}
			else {
				if ($Item->{lijust} =~ /r/) {
					$text->transform( -translate => [$Item->{lileft}+$Item->{liwidth}+10,$Ypos]);
					$text->text_right($Cell[$Item->{lisource}]);
				}
				else {
					$text->transform( -translate => [$Item->{lileft},$Ypos]);
					$text->text($Cell[$Item->{lisource}]);
				}
			}
		}

		$Ypos = $New_Ypos - 25;
		$nettotal += $Cell[3];
		$vattotal += $Cell[5];
		$invtotal += $Cell[3] + $Cell[5];

		if ($Ypos < 200) {
			$page = $pdf->page();
			&set_new_page;
		}
	}
}

#  Finally, enter the totals

$text->lead('28');

foreach $Calc (@Calc) {
	if ($Calc->{libold} =~ /Y/i) {
		$text->font($font_bold,$Calc->{lisize} );
	}
	else {
		$text->font($font, $Calc->{lisize});
	}
	$text->lead($Calc->{lisize} + 2);
	$text->transform( -translate => [$Calc->{lileft}+$Calc->{liwidth}+10,830-$Calc->{litop}]);
	$text->text_right(sprintf("%1.2f",${$Calc->{lialias}}));
}

#  See if we need an overdue stamp

if ($COOKIE->{DB} eq 'fpa3') {
	$g->image($Testonly,100,200);
}
else {
	if ($invoices->{invstatus} =~ /overdue/i && $Use_stamp =~ /Y/i) {
		$g->image($Stamp,200,260);
	}
}
my $PDF_doc = $pdf->stringify();
$pdf->end;
return ($PDF_doc,$Invoice->{invinvoiceno});
}

sub set_new_page {

###  Form wide parameters  ###

$g = $page->gfx();
$text = $page->text();

############   Variable Data   ####################

$Line_len = 0;


foreach $Header (@Header) {
	if ($Header->{libold} =~ /Y/i) {
		$text->font($font_bold,$Header->{lisize} );
	}
	else {
		$text->font($font, $Header->{lisize});
	}
	$text->lead($Header->{lisize} + 2);
	$text->transform( -translate => [$Header->{lileft},830-$Header->{litop}]);
	if ($Header->{lisource} =~ /concat/i) {	#  these are multi line
		@Line = split(/\n/,${$Header->{litable}}->{$Header->{lialias}});
		foreach (@Line) {
			$text->text($_);
			$text->cr();
		}
	}
	else {
		if ($Header->{lijust} =~ /r/i) {
			$text->text_right(${$Header->{litable}}->{$Header->{lialias}});
		}
		else {
			$text->text(${$Header->{litable}}->{$Header->{lialias}});
		}
	}
}

#  Set the line item block settings

foreach $Item (@Items) {
	if ($Item->{lialias} =~ /desc/i) {
		$Ypos = 830 - $Item->{litop};
		$Xpos = $Item->{lileft};
	}
}
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
   x     => $Xpos,
   w     => $Layout->{descwidth},
   h     => $Layout->{descheight},
   align => 'left',
});
}
1;
