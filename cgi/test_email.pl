#!/usr/bin/perl
	
use MIME::Base64;

$PDF_data = "I'm thinking of buying a dog.  What breed do you think would most suit me given that I live in a town and have 3 young children?";

$Encoded_msg = encode_base64($PDF_data);

open(EMAIL,"| /usr/sbin/sendmail -t");
print EMAIL<<EOD;
X-Priority: 3
X-Mailer: Postfix v2.0
X-MimeOLE: Produced By Microsoft MimeOLE V5.50.4133.2400
X-MSMail-Priority: Normal
Message-Id: <CE9D7C3A-BCD9-437E-8725-09B3E5F1BD14>
From: M P Access Services  <fpainvoices\@corunnasystems.co.uk>
To: Maria_Andrews\@heightforhire.ie
Reply-To: M P Access Services <michaelpitt28\@gmail.com
cc: michaelpitt28\@gmail.com
EOD

print EMAIL <<EOD;
Subject: I am thinking of getting a dog
MIME-Version: 1.0
Content-Type: multipart/mixed;
        boundary="----=_NextPart_000_001D_01C0B074.94357480"

This is a multi-part message in MIME format.
 
------=_NextPart_000_001D_01C0B074.94357480
Content-Type: text/plain;
        charset="iso-8859-1"

I'm wondering whether to get a dog.

------=_NextPart_000_001D_01C0B074.94357480
Content-Type: application/pdf;
        name="dogtext.pdf"
Content-Transfer-Encoding: base64
Content-Disposition: attachment;
        filename="dogtext.pdf"

$Encoded_msg 

------=_NextPart_000_001D_01C0B074.94357480--

EOD
close(EMAIL);

exit;

