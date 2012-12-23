#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  Script to email an invoice / credit note

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

use CGI;
use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");

$Data = new CGI;
%FORM = $Data->Vars;

#  Do some basic validation

$Errs = "";

unless ($FORM{invcusemail}) { $Errs .= "<li>You have not entered an email address.</li>\n"; }

if ($Errs) {
        print<<EOD;
Content-Type: text/plain

Errors!

$Errs
EOD
}
else {

	use MIME::Base64;

	if ($FORM{layid} > 0) {
		require "/usr/local/httpd/cgi-bin/fpa/pdf_layout.ph";
		($PDF_data,$Invoice_no) = &pdf_invoicel($FORM{invid},$FORM{pdfstamp},'',$FORM{layid});
	}
	else {
		require "/usr/local/httpd/cgi-bin/fpa/pdf_invoice.ph";
		($PDF_data,$Invoice_no) = &pdf_invoice($FORM{invid},$FORM{pdfstamp},'',$FORM{layid});
	}

        $Encoded_msg = encode_base64($PDF_data);

        open(EMAIL,"| /usr/sbin/sendmail -t");
        print EMAIL<<EOD;
From: $COOKIE->{TAG} <fpainvoices\@corunna.com>
To: $FORM{invcusemail}
Reply-To: $COOKIE->{TAG} <$COOKIE->{ID}>
EOD
	if ($FORM{pdfcopy} =~ /Y/i) {
		print EMAIL <<EOD;
cc: $COOKIE->{ID}
EOD
	}
	print EMAIL <<EOD;
Subject: $FORM{pdfsubj}
MIME-Version: 1.0
Content-Type: multipart/mixed;
        boundary="----=_NextPart_000_001D_01C0B074.94357480"
Message-Id: <$Checkid::Cookie{'fpa-cookie'}>
From: $COOKIE->{TAG} <invoices\@corunna.com>
Reply-To: $COOKIE->{TAG} <$COOKIE->{ID}> 
X-Priority: 3
X-Mailer: Postfix v2.0
X-MimeOLE: Produced By Microsoft MimeOLE V5.50.4133.2400
X-MSMail-Priority: Normal

This is a multi-part message in MIME format.
 
------=_NextPart_000_001D_01C0B074.94357480
Content-Type: text/plain;
        charset="iso-8859-1"

$FORM{pdfmsg}

------=_NextPart_000_001D_01C0B074.94357480
Content-Type: application/pdf;
        name="$Invoice_no.pdf"
Content-Transfer-Encoding: base64
Content-Disposition: attachment;
        filename="$Invoice_no.pdf"

$Encoded_msg 

------=_NextPart_000_001D_01C0B074.94357480--

EOD
        close(EMAIL);

	print<<EOD;
Content-Type: text/plain

OK-Your invoice has been sent-update_invoice.pl?$FORM{invid}
EOD
}
$dbh->disconnect;
exit;

