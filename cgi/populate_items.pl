#!/usr/bin/perl

#  Script to populate the items dataset from the invitems html of invoices

use DBI;
$dbh = DBI->connect("DBI:mysql:fpa");

$Sts = $dbh->do("delete from items");

$Companies = $dbh->prepare("select reg_id,id,comvatscheme from companies");
$Companies->execute;
while ($Company = $Companies->fetchrow_hashref) {
	$COOKIE->{ACCT} = "$Company->{reg_id}+$Company->{id}";
	$COOKIE->{VAT} = $Company->{comvatscheme};

	$Invoices = $dbh->prepare("select id,invinvoiceno,invtype,invcoa,invprintdate,invitems from invoices where acct_id='$COOKIE->{ACCT}' and invstatuscode > 1");
	$Invoices->execute;
	while ($Invoice = $Invoices->fetchrow_hashref) {

		$Invoice->{invitems} =~ s/^.*<\/th>.*?<\/tr>//is;

		$Invoice->{invitems} =~ tr/\r\n//d;			#  remove any newlines
		$Invoice->{invitems} =~ s/<tbody.*?>//ig;		#  Remove any additional tbody tags
		$Invoice->{invitems} =~ s/<\/tbody>//ig;
		$Invoice->{invitems} =~ s/<\/table>//ig;		#  Remove table end tag
		$Invoice->{invitems} =~ s/<tr.*?>//gis;		#  Remove all row start tags

		@Row = split(/\<\/tr\>/,$Invoice->{invitems});	#  Split rows based on row end tags
		for $Row (@Row) {				#  for each row
		        $Row =~ s/<td.*?>//gis;			#  Remove all col start tags
	        	@Cell = split(/\<\/td\>/,$Row);		#  Split cols based on col end tags
			if ($Cell[1]) {		#  ie make sure we don't pick up the last (</table>) line

#  remove any date/increment brackets

			        $Cell[0] =~ s/\[(\%|\+|\-) //g;
			        $Cell[0] =~ s/ (\%|\+|\-)\]//g;

#  Convert ampersands

		        	$Cell[0] =~ s/\&amp;/\&/ig;

				$Cell[0] =~ s/^\s+//;		#  Trim leading spaces

			        if ($COOKIE->{VAT} =~ /N/i) {
					$Sts = $dbh->do("insert into items (acct_id,inv_id,itminvoiceno,itmtype,itmqty,itmdesc,itmtotal,itmdate,itmcat) values ('$COOKIE->{ACCT}',$Invoice->{id},'$Invoice->{invinvoiceno}','$Invoice->{invtype}','$Cell[2]','$Cell[0]','$Cell[3]','$Invoice->{invprintdate}','$Cell[5]')");
			        }
		        	else {
					$Sts = $dbh->do("insert into items (acct_id,inv_id,itminvoiceno,itmtype,itmqty,itmdesc,itmtotal,itmvat,itmvatrate,itmdate,itmcat) values ('$COOKIE->{ACCT}',$Invoice->{id},'$Invoice->{invinvoiceno}','$Invoice->{invtype}','$Cell[2]','$Cell[0]','$Cell[3]','$Cell[5]','$Cell[4]','$Invoice->{invprintdate}','$Cell[7]')");
			        }
			}
		}
	}
}
sub Convert_Cols {
	my $Col = shift;
	$Col =~ s/\n/<br\/>/g;
	return $Col;
}
1;
