#!/usr/bin/perl

#  Script to run through all due recurring invoices

$Dte = `date`;

warn "Rec Invoices running at $Dte\n";

require "/usr/local/git/fpa/cgi/process_invoice.ph";

@RepeatFreq = ('','date_add(invprintdate,interval 7 day)','date_add(invprintdate,interval 14 day)','date_add(invprintdate,interval 28 day)','date_add(invprintdate,interval 42 day)','date_add(invprintdate,interval 56 day)','date_add(invprintdate,interval 84 day)','date_add(invprintdate,interval 1 month)','last_day(date_add(invprintdate,interval 1 month))','date_add(last_day(invprintdate),interval 1 day)','date_add(invprintdate,interval 3 month)','date_add(invprintdate,interval 6 month)','date_add(invprintdate,interval 1 year)');

@Month = ('','January','February','March','April','May','June','July','August','September','October','November','December');

$COOKIE->{ACCT} = '';
$COOKIE->{USER} = "auto invoices";
$No_of_Invoiceis = 0;
$Invoices_text = '';
$Ctr = 0;

use DBI;
use MIME::Base64;
require "/usr/local/httpd/cgi-bin/fpa/pdf_layout.ph";
require "/usr/local/httpd/cgi-bin/fpa/pdf_invoice.ph";

$dbh = DBI->connect("DBI:mysql:fpa");

$BCompanies = $dbh->prepare("select comname,comvatscheme,regmembership,regemail,datediff(comsubdue,now()) as datediff from companies left join registrations using (reg_id) where reg_id=? and id=?");
$RecInvoices = $dbh->prepare("select *,date_format(invprintdate,'%d-%b-%y') as printdate,date_format(invprintdate,'%c') as invmonth,date_format(invprintdate,'%Y') as invyear from invoice_templates where acct_id='1+1' and not isnull(invprintdate) and invprintdate <= now()");
$RecInvoices->execute;

warn "No of invoices found = ".$RecInvoices->rows."\n";

while ($RecInvoice = $RecInvoices->fetchrow_hashref) {
	$Ctr++;

#  Get new company's VAT scheme

	if ($COOKIE->{ACCT} ne $RecInvoice->{acct_id}) {
		if ($COOKIE->{ACCT} && $No_of_invoices > 0) {

        		open(SUMEMAIL,"| /usr/sbin/sendmail -t");
		        print SUMEMAIL<<EOD;
From: Auto-Invoices <fpainvoices\@corunna.com>
To: $BCompany->{regemail}
Subject: $No_of_Invoices FreePlus Invoices have been generated for you

The following invoices have been automatically generated for you today:-

$Invoices_Text

Thank you for using FreePlus Accounts

The FreePlus Accounts team
EOD
			close(SUMEMAIL);
		}
		$No_of_Invoices = 0;
		$Invoices_Text = '';

		$COOKIE->{ACCT} = $RecInvoice->{acct_id};
		($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});
		$BCompanies->execute($Reg_id,$Com_id);
		$BCompany = $BCompanies->fetchrow_hashref;
		$COOKIE->{VAT} = $BCompany->{comvatscheme};
		$COOKIE->{PLAN} = $BCompany->{regmembership};
	}

	if ($BCompany->{datediff} >= 0) {		#  make sure he is still subscribing

		%FORM = %$RecInvoice;

#  Before we do anything else, set the invcoa depending on whether invcusregion = UK/EU/NEU.

        	$FORM{invcusregion} = $FORM{invcusregion} || 'UK';

	        if ($FORM{invcusregion} =~ /UK/i) {
        	        $FORM{invcoa} = "4000";
	        }
        	elsif ($FORM{invcusregion} =~ /NEU/i) {
                	$FORM{invcoa} = "4200";
	        }
        	else {
                	$FORM{invcoa} = "4100";
	        }

		$FORM{submit} = 'Final';
		$FORM{id} = '';
		$FORM{invprintdate} = $RecInvoice->{printdate};

#  Sustitute any template text into items or remarks

		$FORM{invitems} =~ s/\[\# (.+?) #\]/&sub_format($1,$RecInvoice->{invmonth},$RecInvoice->{invyear})/esmg;
		$FORM{invremarks} =~ s/\[\# (.+?) #\]/&sub_format($1,$RecInvoice->{invmonth},$RecInvoice->{invyear})/esmg;
		$FORM{invdesc} =~ s/\[\# (.+?) #\]/&sub_format($1,$RecInvoice->{invmonth},$RecInvoice->{invyear})/esmg;

		&save_invoice('final');

#  Now that we have an invoice no, substitute any text into the emailsubjk and emailmsg

		$FORM{invemailsubj} =~ s/\[\# (.+?) #\]/&sub_format($1,$RecInvoice->{invmonth},$RecInvoice->{invyear})/esmg;
		$FORM{invemailmsg} =~ s/\[\# (.+?) #\]/&sub_format($1,$RecInvoice->{invmonth},$RecInvoice->{invyear})/esmg;
		$BTot = sprintf('%1.2f',$FORM{invtotal}+$FORM{invvat});
		$Invoices_Text .=<<EOD;
   $FORM{invinvoiceno}  -  $FORM{invcusname}
				($BTot)		-  $FORM{invdesc}

EOD

		$No_of_Invoices++;
		&send_email;

#  Then update or delete the template for the next run

		if ($RecInvoice->{invlastinv} <= $RecInvoice->{invnextinv}) {
			$Sts = $dbh->do("delete from invoice_templates where acct_id='$COOKIE->{ACCT}' and id=$RecInvoice->{id}");
		}
		else {
			$Sts = $dbh->do("update invoice_templates set invprintdate=$RepeatFreq[$RecInvoice->{invrepeatfreq}],invnextinv=invnextinv+1 where acct_id='$COOKIE->{ACCT}' and id=$RecInvoice->{id}");
		}
	}
}

if ($COOKIE->{ACCT} && $No_of_Invoices > 0) {
	open(SUMEMAIL,"| /usr/sbin/sendmail -t");
        print SUMEMAIL<<EOD;
From: Auto-Invoices <fpainvoices\@corunna.com>
To: $BCompany->{regemail}
cc: doug.conran\@corunna.com
Subject: $No_of_Invoices FreePlus Invoices have been generated for you

The following invoices have been automatically generated for you today:-

$Invoices_Text

Thank you for using FreePlus Accounts

The FreePlus Accounts team
EOD
	close(SUMEMAIL);
}

$BCompanies->finish;
$RecInvoices->finish;
$dbh->disconnect;

exit;

sub sub_format {

##  Sort out substitutions

	my $Txt = $_[0];

	$Txt =~ tr/ //d;
	my $InvMth = $_[1];
	my $InvYr = $_[2];
	my $InvText = '';

	($PartA,$PartB) = split(/\,/,$Txt);
	if ($PartA =~ /^M/) {
		($PartA,$Added_Months) = split(/\+/,$PartA);
		$InvMth += $Added_Months;
		while ($InvMth > 12) {
			$InvYr++;
			$InvMth -= 12;
		}

		$InvText = $Month[$InvMth];

		if ($PartA =~ /MTH/) { $InvText = substr($InvText,0,3); }
		if ($PartB =~ /^Y/) {
			if ($PartB =~ /YR/) { $InvYr =~ s/\d\d(\d\d)/$1/; }
			$InvText .= " $InvYr";
		}
	}
	elsif ($PartA =~ /INVNO/) {
		$InvText = $FORM{invinvoiceno};
	}
	elsif ($PartA =~ /INVDATE/) {
		$InvText = $RecInvoice->{pritdate};
	}
	elsif ($PartA =~ /THISINV/) {
		$InvText = $RecInvoice->{invnextinv};
	}
	elsif ($PartA =~ /LASTINV/) {
		$InvText = $RecInvoice->{invlastinv};
	}
	else {
		$InvText = '';
	}
 
	return $InvText;
}

sub send_email {

	if ($FORM{invlayout} > 0) {
		($PDF_data,$Invoice_no) = &pdf_invoicel($FORM{id},'N','',$FORM{invlayout});
	}
	else {
		($PDF_data,$Invoice_no) = &pdf_invoice($FORM{id},'N','',$FORM{invlayout});
	}

        $Encoded_msg = encode_base64($PDF_data);

        open(EMAIL,"| /usr/sbin/sendmail -t");
        print EMAIL<<EOD;
From: $BCompany->{comname} <fpainvoices\@corunna.com>
To: $FORM{invcusemail}
Reply-To: $BCompany->{comname} <$BCompany->{regemail}>
EOD
	if ($FORM{invemailcopy} =~ /Y/i) {
		print EMAIL <<EOD;
cc: $BCompany->{regemail}
EOD
	}
	print EMAIL <<EOD;
Subject: $FORM{invemailsubj}
MIME-Version: 1.0
Content-Type: multipart/mixed;
        boundary="----=_NextPart_000_001D_01C0B074.94357480"
Message-Id: <$$.$Ctr>
From: $BCompany->{comname} <$BCompany->{regemail}> 
X-Priority: 3
X-Mailer: Postfix v2.0
X-MimeOLE: Produced By Microsoft MimeOLE V5.50.4133.2400
X-MSMail-Priority: Normal

This is a multi-part message in MIME format.
 
------=_NextPart_000_001D_01C0B074.94357480
Content-Type: text/plain;
        charset="iso-8859-1"

$FORM{invemailmsg}

------=_NextPart_000_001D_01C0B074.94357480
Content-Type: application/pdf;
        name="$FORM{invinvoiceno}.pdf"
Content-Transfer-Encoding: base64
Content-Disposition: attachment;
        filename="$FORM{invinvoiceno}.pdf"

$Encoded_msg 

------=_NextPart_000_001D_01C0B074.94357480--

EOD
        close(EMAIL);
}
