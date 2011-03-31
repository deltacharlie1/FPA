#!/usr/bin/perl

use DBI;
$dbh = DBI->connect("DBI:mysql:fpa");

use MIME::Base64;

require "/usr/local/httpd/cgi-bin/fpa/pdf_statement.ph";

$Stmt_period = `date +%B`;
chomp($Stmt_period);
$Msg_id_suffix = 0;

#  For each company with comstmts date today or in the future

$aCompanies = $dbh->prepare("select reg_id,id,comcontact,comname,comstmtmsg,comemail,comvatscheme,if(compt_logo>now(),'1','') as pt_logo from companies where datediff(comstmts,now())>=0");
$aCompanies->execute;
while ($aCompany = $aCompanies->fetchrow_hashref) {

	$COOKIE->{ACCT} = $aCompany->{reg_id}.'+'.$aCompany->{id};
	$COOKIE->{VAT} = $aCompany->{comvatscheme};
	$COOKIE->{PT_LOGO} = $aCompany->{pt_logo};

	unless ($aCompany->{comstmtmsg}) {
		$aCompany->{comstmtmsg} = sprintf<<EOD
Please find our statment for $Stmt_period attached to this email.

Yours sincerely

$aCompany->{comname}
EOD
	}

#  Now get each customer who is to receive a statement

	$aCustomers = $dbh->prepare("select id,cusstmtmsg,cusemail,cusname from customers where cusautostmts='Y' and acct_id='$COOKIE->{ACCT}'");
	$aCustomers->execute;
	while ($aCustomer = $aCustomers->fetchrow_hashref) {

		if ($aCustomer->{cusemail}) {

			$Msg_id_siffix++;

			$aCustomer->{cusstmtmsg} = $aCustomer->{cusstmtmsg} || $aCompany->{comstmtmsg};
			$aCustomer->{cusstmtmsg} =~ s/\<month\#\>/$Stmt_period/;

			($PDF_data,$Date) = &pdf_statement($aCustomer->{id});

		        $Encoded_msg = encode_base64($PDF_data);

			open(EMAIL,"| /usr/sbin/sendmail -t");
		        print EMAIL<<EOD;
From: $aCompany->{comcontact} <fpastatements\@corunna.com>
To: $aCustomer->{cusemail}
cc: $aCompany->{comemail}
Reply-To: $aCompany->{comcontact} <$aCompany->{comemail}>
Subject: $aCompany->{comname} statement for $Stmt_period
MIME-Version: 1.0
Content-Type: multipart/mixed;
        boundary="----=_NextPart_000_001D_01C0B074.94357480"
Message-Id: <$$-$Msg_id_suffix}>
From: $aCompany->{comcontact} <$aCompany->{comemail}>
X-Priority: 3
X-Mailer: Postfix v2.0
X-MimeOLE: Produced By Microsoft MimeOLE V5.50.4133.2400
X-MSMail-Priority: Normal

This is a multi-part message in MIME format.
 
------=_NextPart_000_001D_01C0B074.94357480
Content-Type: text/plain;
        charset="iso-8859-1"

$aCustomer->{cusstmtmsg}

------=_NextPart_000_001D_01C0B074.94357480
Content-Type: application/pdf;
        name="${Stmt_period}_stmt.pdf"
Content-Transfer-Encoding: base64
Content-Disposition: attachment;
        filename="${Stmt_period}_stmt.pdf"

$Encoded_msg 

------=_NextPart_000_001D_01C0B074.94357480--

EOD
		        close(EMAIL);
		}
	}
}
$aCustomers->finish;
$aCompanies->finish;
$dbh->disconnect;
exit;

