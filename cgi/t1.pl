#!/usr/bin/perl
require "/usr/local/httpd/cgi-bin/fpa/process_invoice.ph";
require "/usr/local/httpd/cgi-bin/fpa/process_purchase.ph";

while (<>) {
	$FORM{stmtdata} .= $_;
}

$FORM{stmtdata} =~ tr/\r\n//d;			#  Remove newlines
$FORM{stmtdata} =~ s/>\s*?</></g;		#  remove spaces between tags

$FORM{stmtdata} =~ s/^.*?<tbody id/<tbody id/i;	#  REmove everything before the first relevant tbody

$FORM{stmtdata} =~ s/<tbody>//ig;		#  Remove non id marked tbodys
$FORM{stmtdata} =~ s/<\/tbody></</ig;		#  Remove tbody end tags
$FORM{stmtdata} =~ s/<table.*?>//ig;		#  Remove table start tags
$FORM{stmtdata} =~ s/<\/table>//ig;		#  Remove table end tags
# $FORM{stmtdata} =~ s/<tr.*?>//ig;
# $FORM{stmtdata} =~ s/<td.*?>//ig;
# $FORM{stmtdata} =~ s/<\/tr>/\n/ig;
#  Now take what we have and step through the tbodies
# exit;

$FORM{stmtdata} .= "<tbody";

 while ($FORM{stmtdata} =~ s/^(\<tbody.*?<tbody)/&tbod($1)/ise) {};
# $FORM{stmtdata} =~ s/(body.*body)/&tbod($1)/imge;
print "\n============\n\n".$FORM{stmtdata}."\n";

exit;

sub tbod {
	$Tbody = $_[0];
	$Tbody =~ s/\<tbody.*?>//ig;

	$First = "1";
	$Txntype = "";
	$Invoice_ids = "";

	$Tbody =~ s/\<tr.*?>//ig;		#  get rid of opening tr tags	
	$Tbody =~ s/\<td.*?>//ig;		#  get rid of opening td tags	
	$Tbody =~ s/<\/tr>/\n/ig;		#  substitute newlines for td closing tags
	$Tbody =~ s/<\/td>/\t/ig;		#  substitute tabs for td closing tags

	@Rows = split(/\n/,$Tbody);

	foreach $Row (@Rows) {
		@Cells = split(/\t/,$Row);
		if ($First) {			#  First row so just store bank statement detail for transaction
			$FORM{invprintdate} = $Cells[0];
			$FORM{invdesc} = $Cells[1];
			$FORM{txnamount} = $Cells[2];
			$FORM{cus_id};
			$FORM{invcusname};
			$FORM{txnmethod} = '1200';

			$First = "";
		}
		else {
			if ($Cells[1] =~ /pay/i) {	#  get the customer name and update FORM{invcusname}
				$Invoice_ids .= "$Cells[0],";
				$FORM{cus_id} = "??";
				$FORM{invcusname} = "???";
			}
			elsif ($Cells[1] =~ /rec/i) 





	$Tbody =~ s/<\/td>/\t/ig;
	if ($Tbody =~ /Delete/) {
		print "tbody = $Tbody\n\n";
	}
	return "<tbody";
}

