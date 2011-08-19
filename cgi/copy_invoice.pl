#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to copy an existing invoice (but with a new invoice no and set to draft status)

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");
unless ($COOKIE->{NO_ADS}) {
	require "/usr/local/git/fpa/cgi/display_adverts.ph";
	&display_adverts();
}


$Existing_no = $ENV{QUERY_STRING};

#  Get the existing invoice

my $Invoices = $dbh->prepare("select cus_id,invcusref,invtype,invcusname,invcusaddr,invcuspostcode,invcusregion,invcuscontact,invcusemail,invcusterms,invtotal,invvat,invitemcount,invitems,invdesc,invstatuscode from invoices where acct_id='$COOKIE->{ACCT}' and id=$Existing_no");
$Invoices->execute;
my @Invoice = $Invoices->fetchrow;
$Invoices->finish;

#  Escape any apostrophes

for ($i=0; $i<15; $i++) {
	$Invoice[$i] =~ s/\'/\\\'/g;
}

#  Now create the new invoice details

#if ($Invoice[15] > 1) {		#  Add the amend/delete buttons to the line item block

#  First do the Heading

#	$Invoice[13] =~ tr/\r\n//d;			#  Get rid of all newlines
#	$Invoice[13] =~ s/\/tr>/\/tr>\n/ig;		#  Split each row into a line of its own
#	@Row = split(/\n/,$Invoice[13]);		#  Put each row into an array
#	$Row[0] =~ s/\<\/tr>/<th style="text-align: center;" width="70">Edit<\/th>\<\/tr>/;	#  Add the Edit column header
#	for $Row (1..$#Row) {
#		my $Indx = $Row - 1;
#		$Row[$Row] =~ s/\<\/tr>/<td nowrap="nowrap"><input value="Amd" id="a$Indx" type="button" onclick="amd(this);" \/> <input value="Del" id="d$Indx" type="button" onclick="dlt(this);" \/><\/td><\/tr>/;	#  Add Amend/Delete buttons
#	}
#	$Invoice[13] = join("\n",@Row);
#}

#  Next insert the new invoice

$Sts = $dbh->do("insert into invoices (acct_id,cus_id,invcusref,invtype,invcusname,invcusaddr,invcuspostcode,invcusregion,invcuscontact,invcusemail,invcusterms,invcreated,invtotal,invvat,invstatus,invstatuscode,invstatusdate,invitemcount,invitems,invdesc) values ('$COOKIE->{ACCT}',$Invoice[0],'$Invoice[1]','$Invoice[2]','$Invoice[3]','$Invoice[4]','$Invoice[5]','$Invoice[6]','$Invoice[7]','$Invoice[8]','$Invoice[9]',now(),'$Invoice[10]','$Invoice[11]','Draft','1',now(),$Invoice[12],'$Invoice[13]','$Invoice[14]')");

#  Get the new id

my $New_inv_id = $dbh->last_insert_id(undef, undef, qw(invoices undef));

#  and finally display it using update_invoice.pl

print<<EOD;
Content-Type: text/html
Status: 301
Location: /cgi-bin/fpa/update_invoice.pl?$New_inv_id

EOD

$dbh->disconnect;
exit;
