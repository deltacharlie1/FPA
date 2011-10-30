#!/usr/bin/perl

#  script to display the main cover sheet updating screen

read(STDIN, $Buffer, $ENV{'CONTENT_LENGTH'});

# warn "$Buffer\n\n";

#  Returnd Data = 
#  type=subscribe&fired_at=2011-10-28+18%3A18%3A30&data%5Bid%5D=2b89a96477&data%5Bemail%5D=dwc%40corunna.com&data%5Bemail_type%5D=html&data%5Bip_opt%5D=109.149.49.74&data%5Bweb_id%5D=288790853&data%5Bmerges%5D%5BEMAIL%5D=dwc%40corunna.com&data%5Bmerges%5D%5BFNAME%5D=Doug&data%5Bmerges%5D%5BLNAME%5D=Conran&data%5Blist_id%5D=b4d31d6294

print<<EOD;
Content-Type: text/html
Status: 200 OK

EOD

exit;

