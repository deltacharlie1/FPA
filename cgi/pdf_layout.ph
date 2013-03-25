sub pdf_invoicel {

$Inv_id = $_[0];
$Use_stamp = $_[1];
if ($_[2] =~ /_template/) {
        $Tplt = $_[2];
}
else {
        $Tplt = "";
}
$Layout_id = $_[3];
$Testonly = $_[4];

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

	if ($LI->{lifldcode} =~ /a013/i) {
		$Yrmk = 842 - $LI->{lisize} - $LI->{litop};
#		$Xrmk = $Item->{lileft};
		$Xrmk = $LI->{lileft};
	}
	elsif ($LI->{lifldcode} =~ /a020/) {
		$Litop = 842 - $LI->{lisize} - $LI->{litop};
	}
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
	elsif ($LI->{litable} =~ /customers/i) {
		$S_sel .= $LI->{lisource}." as ".$LI->{lialias}.",";
	}
}

chop($C_sel);
chop($S_sel);
chop($A_sel);
chop($I_sel);

($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});

if ($C_sel) {
	$PCompanies = $dbh->prepare("select $C_sel from companies where reg_id=$Reg_id and id=$Com_id");
	$PCompanies->execute;
	$companies = $PCompanies->fetchrow_hashref;
	$PCompanies->finish;
}
if ($A_sel) {
	$Accts = $dbh->prepare("select $A_sel from accounts where acct_id='$COOKIE->{ACCT}' and acctype='1200'");
	$Accts->execute;
	$accounts = $Accts->fetchrow_hashref;
	$Accts->finish;
}
if ($I_sel) {
	$I_sel .= ",invstatus,invtype";
	$PInvoices = $dbh->prepare("select $I_sel from invoice${Tplt}s where acct_id='$COOKIE->{ACCT}' and id=$Inv_id");
#	$PInvoices = $dbh->prepare("select * from invoice${Tplt}s where acct_id='$COOKIE->{ACCT}' and id=$Inv_id");
	$PInvoices->execute;
	$invoices = $PInvoices->fetchrow_hashref;
	$PInvoices->finish;

	while (($Key,$Value) = each %$invoices) {
		$invoices->{$Key} =~ s/\xc2//g;
	}
}
if ($S_sel) {
	$PCustomers = $dbh->prepare("select $S_sel from invoice${Tplt}s left join customers on(cus_id=customers.id) where invoice${Tplt}s.acct_id='$COOKIE->{ACCT}' and invoice${Tplt}s.id=$Inv_id");
	$PCustomers->execute;
	$customers = $PCustomers->fetchrow_hashref;
	$PCustomers->finish;

	$customers->{delivaddr} = $customers->{delivaddr} || $invoices->{cusaddress};
}
# $dbh->disconnect;

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

if ($invoices->{invtype} =~ /^C/) {
	$invoices->{invtype} = "CREDIT NOTE";
}
elsif ($invoices->{invstatus} =~ /Quote/i) {
	$invoices->{invtype} = "QUOTATION";
}
else {
	$invoices->{invtype} = "INVOICE";
}
if ($invoices->{invstatus} =~ /Draft/i) {
	$invoices->{invtype} = "DRAFT ".$invoices->{invtype};
}

if ($invoices->{custerms} == "0") {
	$invoices->{custerms} = "Due Now";
}
elsif ($invoices->{custerms} =~ /^\d+$/) {
	$invoices->{custerms} .= " Days";
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

$pdf = PDF::API2->open("$Layout->{layfile}");
if ($Layout->{layreversefile}) {
	$Revs = $dbh->prepare("select layfile from invoice_layouts where acct_id='$COOKIE->{ACCT}' and id=$Layout->{layreversefile}");
	$Revs->execute;
	$Rev = $Revs->fetchrow_hashref;
	$Revs->finish;
	$Rev_pdf = PDF::API2->open("$Rev->{layfile}");
}
$page = $pdf->openpage(1);
$font = $pdf->corefont('Helvetica');
$font_bold = $pdf->corefont('Helvetica Bold');

$Overdue = $pdf->image_png('../cgi/overdue.png');
$Paid = $pdf->image_png('/usr/local/git/fpa/htdocs/icons/paid.png');
$Testimg = $pdf->image_png('/usr/local/git/fpa/htdocs/icons/testonly.png');

#  Set out the first page

&set_new_lpage;

$invoices->{invitems} =~ s/^.*?<tr>//is;		#  Remove everything up to the first table row
$invoices->{invitems} =~ s/^.*?<tr>//is;		#  Then again to remove all headers
$invoices->{invitems}=~ s/<tr.*?>//gis;			#  Remove all row start tags

@Row = split(/\<\/tr\>/i,$invoices->{invitems});
for $Row (@Row) {

	last if $Row =~ /\<\/table\>/i;

	if ($Ypos < 842 - $Litop - $Layout->{descheight} + 20) {

#  Is there a reverse side?

		if ($Rev_pdf) {
			$page = $pdf->importpage($Rev_pdf,1,0);
		}
		$page = $pdf->importpage($pdf,1,0);
		&set_new_lpage;
	}

	$Row =~ s/^.*?<td.*?>//is;
        $Row =~ s/<td.*?>//gis;

        @PCell = split(/\<\/td\>/i,$Row);
	if ($PCell[0]) {

#  remove any date/increment brackets

		$PCell[0] =~ s/\[(\%|\+|\-) //g;
		$PCell[0] =~ s/ (\%|\+|\-)\]//g;

#  Convert ampersands

		$PCell[0] =~ s/\&amp;/\&/ig;
		$PCell[0] =~ s/<br\/>/\n/ig;
		$PCell[3] =~ s/<br\/>//ig;
		$PCell[5] =~ s/<br\/>//ig;

		foreach $Item (@Items) {

			if ($Item->{libold} =~ /Y/i) {
				$text->font($font_bold,$Item->{lisize} );
			}
			else {
				$text->font($font, $Item->{lisize});
			}
			$text->lead($Item->{lisize} + 2);
			if ($Item->{lifldcode} =~ /a020/) {
				$Litop = $Item->{litop};
				$tb->y($Ypos);
				$tb->text($PCell[0]);
				($endw, $New_Ypos) = $tb->apply();
			}
			else {
				if ($Item->{lijust} =~ /r/) {
					$text->transform( -translate => [$Item->{lileft}+$Item->{liwidth}+10,$Ypos]);
					$text->text_right($PCell[$Item->{lisource}]);
				}
				else {
					$text->transform( -translate => [$Item->{lileft},$Ypos]);
					$text->text($PCell[$Item->{lisource}]);
				}
			}
		}

		$Ypos = $New_Ypos - 25;
		$nettotal += $PCell[3];
		$vattotal += $PCell[5];
		$invtotal += $PCell[3] + $PCell[5];
	}
}

#  Finally, enter the totals

foreach $Calc (@Calc) {
	if ($Calc->{libold} =~ /Y/i) {
		$text->font($font_bold,$Calc->{lisize} );
	}
	else {
		$text->font($font, $Calc->{lisize});
	}
	$text->lead($Calc->{lisize} + 2);
	$text->transform( -translate => [$Calc->{lileft}+$Calc->{liwidth}+10,842-$Calc->{lisize}-$Calc->{litop}]);
	$text->text_right(sprintf("%1.2f",${$Calc->{lialias}}));
}

if ($Rev_pdf) {
	$page = $pdf->importpage($Rev_pdf,1,0);
}

my $PDF_doc = $pdf->stringify();
$pdf->end;
return ($PDF_doc,$invoices->{invinvoiceno});
}

sub set_new_lpage {

###  Form wide parameters  ###

$g = $page->gfx();
$text = $page->text();
$text->font($font,10);

############   Variable Data   ####################

$Line_len = 0;

#  Set the line item block settings

foreach $Item (@Items) {
	if ($Item->{lialias} =~ /desc/i) {
		$Ypos = 842 - $Item->{lisize} - $Item->{litop};
		$Xpos = $Item->{lileft};
	}
}
# $text->font($font,10);

#  Now do the line items - set up the text block fiexed parameters

$tb = PDF::TextBlock->new({
   pdf   => $pdf,
   page  => $page,
   fonts => {
      default => PDF::TextBlock::Font->new({
         pdf       => $pdf,
         font      => $pdf->corefont( 'Helvetica' ),
         size      => 12,
      }),
   },
   x     => $Xpos,
   w     => $Layout->{descwidth},
   h     => $Layout->{descheight},
   align => 'left',
});

if ($I_sel =~ /invremarks/i) {
	$rb = PDF::TextBlock->new({
   pdf   => $pdf,
   page  => $page,
   fonts => {
      default => PDF::TextBlock::Font->new({
         pdf       => $pdf,
         font      => $pdf->corefont( 'Helvetica' ),
         size      => 12,
      }),
   },
   x     => $Xrmk,
   w     => $Layout->{rmkwidth},
   h     => $Layout->{rmkheight},
   align => 'left',
});
}

foreach $Header (@Header) {
	if ($Header->{libold} =~ /Y/i) {
		$text->font($font_bold,$Header->{lisize} );
	}
	else {
		$text->font($font, $Header->{lisize});
	}
	$text->lead($Header->{lisize} + 2);
	$text->transform( -translate => [$Header->{lileft},842-$Header->{lisize}-$Header->{litop}]);
	if ($Header->{lialias} =~ /addr/i) {	#  these are multi line
		@Line = split(/\n/,${$Header->{litable}}->{$Header->{lialias}});
		foreach (@Line) {
			$text->text($_);
			$text->cr();
		}
	}
	elsif ($Header->{lifldcode} =~ /a013/i) {		#  This is a remark
		$rb->y($Yrmk);
		$rb->text(${$Header->{litable}}->{$Header->{lialias}});
		($endw, $New_Ypos) = $rb->apply();
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

#  See if we need an overdue stamp

if ($COOKIE->{DB} eq 'fpa3' || $Testonly =~ /T/i) {
	$g->image($Testimg,100,200);
}
else {
	if ($invoices->{invstatus} =~ /overdue/i && $Use_stamp =~ /Y/i) {
		$g->image($Overdue,200,260);
	}
	elsif ($invoices->{invstatus} =~ /^paid/i && $Use_stamp =~ /Y/i) {
		$g->image($Paid,200,260);
	}
}
}
1;
