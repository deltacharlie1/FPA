#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to copy an existing invoice and display it as a recurring invoice template

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");

$Existing_no = $ENV{QUERY_STRING};

#  Get the existing invoice

$Invoices = $dbh->prepare("select cus_id,invcusref,invcusname,invcusaddr,invcuspostcode,invcusregion,invcuscontact,invcusemail,invcusterms,invtotal,invvat,invitemcount,invitems,invdesc,invremarks,invlayout from invoices where acct_id='$COOKIE->{ACCT}' and id=$Existing_no");
$Invoices->execute;
$Invoice = $Invoices->fetchrow_hashref;
$Invoices->finish;

#  Escape any apostrophes

for ($i=0; $i<15; $i++) {
	$Invoice[$i] =~ s/\'/\\\'/g;
}

$Invemailsubj = "Invoice [# INVNO #] from $COOKIE->{TAG}";
$Invemailmsg =<<EOD;
Please find our invoice # [# INVNO #] attached.

Yours faithfully

$COOKIE->{TAG}
EOD

$Sts = $dbh->do("insert into invoice_templates (acct_id,cus_id,invcusref,invcusname,invcusaddr,invcuspostcode,invcusregion,invcuscontact,invcusemail,invcusterms,invcreated,invtotal,invvat,invitemcount,invitems,invdesc,invremarks,invlayout,invemailsubj,invemailmsg) values ('$COOKIE->{ACCT}',$Invoice->{cus_id},'$Invoice->{invcusref}','$Invoice->{invcusname}','$Invoice->{invcusaddr}','$Invoice->{invcuspostcode}','$Invoice->{invcusregion}','$Invoice->{invcuscontact}','$Invoice->{invcusemail}','$Invoice->{invcusterms}',now(),'$Invoice->{invtotal}','$Invoice->{invvat}','$Invoice->{invitemcount}','$Invoice->{invitems}','$Invoice->{invdesc}','$Invoice->{invremarks}',$Invoice->{invlayout},'$Invemailsubj','$Invemailmsg')");

#  Get the new id

my $New_inv_id = $dbh->last_insert_id(undef, undef, qw(invoice_templates undef));

#  and finally display it using update_invoice.pl

print<<EOD;
Content-Type: text/html
Status: 302
Location: /cgi-bin/fpa/update_invoice_template.pl?$New_inv_id

EOD

$dbh->disconnect;
exit;
