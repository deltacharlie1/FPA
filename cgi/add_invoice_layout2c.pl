#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to upload an invoice layout

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

use CGI;
use DBI;
use URI::Escape;

%Settings = (
  a001 => { name => 'Invoice Type', table => 'invoices', source => 'invtype', alias => 'invtype', top => '0', left => '610', size => '12', bold => 'N', display => 'N', just => 'l' },
  a002 => { name => 'My Address', table => 'companies', source => 'concat(comname,"\\\\n",comaddress,"  ",compostcode)', alias => 'myaddress', top => '0', left => '610', size => '12', bold => 'N', display => 'N', just => 'l' },
  a003 => { name => 'My Phone No', table => 'companies', source => 'comtel', alias => 'mytel', top => '0', left => '610', size => '12', bold => 'N', display => 'N', just => 'l' },
  a004 => { name => 'My Email Addr', table => 'companies', source => 'comemail', alias => 'myemail', top => '0', left => '610', size => '12', bold => 'N', display => 'N', just => 'l' },
  a005 => { name => 'Customer Addr', table => 'invoices', source => 'concat(invcusname,"\\\\n",invcusaddr,"  ",invcuspostcode)', alias => 'cusaddress', top => '0', left => '610', size => '12', bold => 'N', display => 'N', just => 'l' },
  a006 => { name => 'Customer FAO', table => 'invoices', source => 'invcuscontact', alias => 'cusfao', top => '0', left => '610', size => '12', bold => 'N', display => 'N', just => 'l' },
  a007 => { name => 'Invoice #', table => 'invoices', source => 'invinvoiceno', alias => 'invoiceno', top => '0', left => '610', size => '12', bold => 'N', display => 'N', just => 'l' },
  a008 => { name => 'Invoice Date', table => 'invoices', source => 'date_format(invprintdate,"%d-%b-%y")', alias => 'printdate', top => '0', left => '610', size => '12', bold => 'N', display => 'N', just => 'l' },
  a009 => { name => 'Due Date', table => 'invoices', source => 'date_format(invduedate,"%d-%b-%y")', alias => 'duedate', top => '0', left => '610', size => '12', bold => 'N', display => 'N', just => 'l' },
  a010 => { name => 'Terms', table => 'invoices', source => 'invcusterms', alias => 'custerms', top => '0', left => '610', size => '12', bold => 'N', display => 'N', just => 'l' },
  a011 => { name => 'Customer Ref', table => 'invoices', source => 'invcusref', alias => 'cusref', top => '0', left => '610', size => '12', bold => 'N', display => 'N', just => 'l' },
  a012 => { name => 'VAT Reg', table => 'companies', source => 'comvatno', alias => 'vatno', top => '0', left => '610', size => '12', bold => 'N', display => 'N', just => 'l' },
  a013 => { name => 'Remarks', table => 'invoices', source => 'invremarks', alias => 'remarks', top => '0', left => '610', size => '12', bold => 'N', display => 'N', just => 'l' },
  a014 => { name => 'Net Total', table => 'calc', source => 'calc', alias => 'nettotal', top => '0', left => '610', size => '12', bold => 'N', display => 'N', just => 'r' },
  a015 => { name => 'VAT Total', table => 'calc', source => 'calc', alias => 'vattotal', top => '0', left => '610', size => '12', bold => 'N', display => 'N', just => 'r' },
  a016 => { name => 'Invoice Total', table => 'calc', source => 'calc', alias => 'invtotal', top => '0', left => '610', size => '12', bold => 'N', display => 'N', just => 'r' },
  a017 => { name => 'Company Reg', table => 'companies', source => 'comregno', alias => 'regno', top => '0', left => '610', size => '12', bold => 'N', display => 'N', just => 'l' },
  a018 => { name => 'Bank Sort Code', table => 'accounts', source => 'accsort', alias => 'sortcode', top => '0', left => '610', size => '12', bold => 'N', display => 'N', just => 'l' },
  a019 => { name => 'Bank Acct #', table => 'accounts', source => 'accacctno', alias => 'acctno', top => '0', left => '610', size => '12', bold => 'N', display => 'N', just => 'l' },
  a020 => { name => 'Item Description', table => 'items', source => '0', alias => 'desc', top => '0', left => '610', size => '12', bold => 'N', display => 'N', just => 'l' },
  a021 => { name => 'Item Quantity', table => 'items', source => '2', alias => 'qty', top => '0', left => '610', size => '10', bold => 'N', display => 'N', just => 'l' },
  a022 => { name => 'Item Unit Price', table => 'items', source => '1', alias => 'price', top => '0', left => '610', size => '12', bold => 'N', display => 'N', just => 'r' },
  a023 => { name => 'Item Net Total', table => 'items', source => '3', alias => 'net', top => '0', left => '610', size => '12', bold => 'N', display => 'N', just => 'r' },
  a024 => { name => 'Item VAT Rate', table => 'items', source => '4', alias => 'vrate', top => '0', left => '610', size => '12', bold => 'N', display => 'N', just => 'l' },
  a025 => { name => 'Item VAT Total', table => 'items', source => '5', alias => 'vat', top => '0', left => '610', size => '12', bold => 'N', display => 'N', just => 'r' },
  a026 => { name => 'Item Total', table => 'items', source => '6', alias => 'itmtotal', top => '0', left => '610', size => '12', bold => 'N', display => 'N', just => 'r' },
  a027 => { name => 'Delivery Address', table => 'customers', source => 'cusdeliveryaddr', alias => 'delivaddr', top => '0', left => '610', size => '12', bold => 'N', display => 'N', just => 'l' }
);

$Data = new CGI;
%FORM = $Data->Vars;

#  Get the ACCT from the cookie file (cookie is passed as a parameter)

open(COOKIE,"/projects/tmp/$FORM{cookie}");
while (<COOKIE>) {
	chomp($_);
	($Name,$Value) = split(/\t/,$_);
	$COOKIE->{$Name} = $Value;
	$Cookie{$Name} = $Value;
}
close(COOKIE);

if ($COOKIE->{VAT} =~ /N/i) {
	$Settings{a026}->{source} = 3;
}

$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");
($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});

#  Get the number of existing layouts

$Layouts = $dbh->prepare("select count(*) from invoice_layouts where acct_id='$COOKIE->{ACCT}'");
$Layouts->execute;
@Layout = $Layouts->fetchrow;
$Layouts->finish;

$Errs = "<ol>";

while (( $Key,$Value) = each %FORM) {

#  Remove any bad characters

	$Value =~ tr/\\//d;
	$Value =~ s/\'/\\\'/g;

	if ($Key =~ /form/i) {

#  Split the serialized inputs

		@Parms = split(/\&/,$Value);
		foreach $Parm (@Parms) {
			($k,$v) = split(/\=/,$Parm);
			$v = uri_unescape($v);
			$v =~ s/\+/ /g;
			$PARM{$k} = $v;
			if ($k =~ /layid/ && $v==0 && @Layout[0]>20) {
				$Errs .= "<li>You already have the maximum number of layouts</li>\n";
			}
			if ($k =~ /laydesc/i && length($v) < 1) {
				$Errs .= "<li>You must enter a Layout Description</li>\n";
			}
 		}
	}
	else {
		if ($Key =~ /^a\d\d\d$/) {
			$Settings{$Key}->{display} = 'Y';
		}
		if ($Key eq "file" && $Value !~ /.*\.pdf$/i) {
			$Errs .= "<li>The Layout file must be in PDF format</li>\n";
		}
	}
}

$handle = $Data->upload("file");

$Original = "";
while (<$handle>) {
        $Original .= $_;
}

if (length($Original) > 61440) {
	$Errs .= "<li>Your layout file cannot be greater than 60k</li>\n";
}

if (length($Errs) < 6) {
	$PARM{layspace} = $PARM{layspace} || 25;

	$Settings{a008}->{source} =~ s/\%d-\%b-\%y/$PARM{laydateformat}/;
	$Settings{a009}->{source} =~ s/\%d-\%b-\%y/$PARM{laydateformat}/;

#  Get the Docs dir into which to store the file

	$Companies = $dbh->prepare("select comdocsdir from companies where reg_id=$Reg_id and id=$Com_id");
	$Companies->execute;
	$Company = $Companies->fetchrow_hashref;
	$Companies->finish;

	if (length($Company->{comdocsdir}) > 5) { 
		$Width = 595;
		$Height = 842;

		if ($FORM{file} !~ /pdf$/i) {
			use Image::Magick;
			$Img = Image::Magick->new;
			$status = $Img->BlobToImage($Original);
			($Width,$Height) = $Img->Get('width','height');
			$Original = $Img->ImageToBlob(magick=>'pdf');
		}

		open(IMG,">/projects/fpa_docs/".$Company->{comdocsdir}."/".$FORM{file}) || warn "unable to open file - /projects/fpa_docs/$Company->{comdocsdir}/$FORM{file}\n";
		print IMG $Original;
		close(IMG);

#  If this is a new layout, add the details, otherwise update the existing details

		if ($PARM{id} == 0) {
			$Sts = $dbh->do("insert into invoice_layouts (acct_id,layfile,laydesc,laydateformat,layreversefile,layspace) values ('$COOKIE->{ACCT}','/projects/fpa_docs/$Company->{comdocsdir}/$FORM{file}','$PARM{laydesc}','$PARM{laydateformat}','$PARM{layreversefile}',$PARM{layspace})");
			$New_inv_id = $dbh->last_insert_id(undef, undef, qw(invoice_layouts undef));

			while (($Key,$Value) = each %Settings) {

				$Value->{top} =~ s/(.*)\..*/$1/;
				$Sts = $dbh->do("insert into invoice_layout_items (acct_id,link_id,lifldcode,lidispname,litable,lisource,lialias,litop,lileft,lisize,libold,lidisplay,lijust) values ('$COOKIE->{ACCT}',$New_inv_id,'$Key','$Value->{name}','$Value->{table}','$Value->{source}','$Value->{alias}','$Value->{top}','$Value->{left}','$Value->{size}','$Value->{bold}','$Value->{display}','$Value->{just}')");
			}
		}
		else {
			$Sts = $dbh->do("update invoice_layouts set layfile='/projects/fpa_docs/$Company->{comdocsdir}/$FORM{file}',laydesc='$PARM{laydesc}',laydateformat='$PARM{laydateformat}',layreversefile='$PARM{layreversefile}',layspace=$PARM{layspace} where id=$PARM{id} and acct_id='$COOKIE->{ACCT}'");
			$Sts = $dbh->do("update invoice_layout_items set lisource='date_format(invprintdate,\"$PARM{laydateformat}\")' where lialias='printdate' and link_id=$PARM{id} and acct_id='$COOKIE->{ACCT}'");
			$Sts = $dbh->do("update invoice_layout_items set lisource='date_format(invduedate,\"$PARM{laydateformat}\")' where lialias='duedate' and link_id=$PARM{id} and acct_id='$COOKIE->{ACCT}'");
		}
	}
	else {
		$Errs .= "<li>There is a problem adding/updating this layout.  Please contact Technical Support</li>\n";
	}
}

if (length($Errs) > 5) {
	print<<EOD;
Content-Type: text/html

<html>
<head>
<title>Errors</title>
</head>
<body>
<p>
<h2><center>You have Errors</h2></center>
$Errs
</ol>
<p><center><input type="button" name="pl1" id="pl1" value="Click to Refresh" onclick="location.reload(true);"/></center>
</body>
</html>
EOD
}
else {
	print "1";
}

$dbh->disconnect;
exit;
