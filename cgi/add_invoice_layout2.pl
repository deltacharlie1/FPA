#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to upload an invoice layout

use CGI;
use DBI;

%Settings = (
  a001 => { table => 'invoices', source => 'invtype', alias => 'invtype', top => '842', left => '0', size => '12', bold => 'N', display => 'N', just => 'l' },
  a002 => { table => 'companies', source => 'concat(comname,"\\n",comaddress,"  ,compostcode)', alias => 'myaddress', top => '842', left => '0', size => '12', bold => 'N', display => 'N', just => 'l' },
  a003 => { table => 'companies', source => 'comtel', alias => 'mytel', top => '842', left => '0', size => '12', bold => 'N', display => 'N', just => 'l' },
  a004 => { table => 'companies', source => 'comemail', alias => 'myemail', top => '842', left => '0', size => '12', bold => 'N', display => 'N', just => 'l' },
  a005 => { table => 'invoices', source => 'concat(invcusname,"\\n",invcusaddr"  ",invcuspostcode)', alias => 'cusaddress', top => '842', left => '0', size => '12', bold => 'N', display => 'N', just => 'l' },
  a006 => { table => 'invoices', source => 'invcuscontact', alias => 'cusfao', top => '842', left => '0', size => '12', bold => 'N', display => 'N', just => 'l' },
  a007 => { table => 'invoices', source => 'invinvoiceno', alias => 'invoiceno', top => '842', left => '0', size => '12', bold => 'N', display => 'N', just => 'l' },
  a008 => { table => 'invoices', source => 'date_format(invprintdate,"%d-%b-%y")', alias => 'printdate', top => '842', left => '0', size => '12', bold => 'N', display => 'N', just => 'l' },
  a009 => { table => 'invoices', source => 'date_format(invduedate,"%d-%b-%y")', alias => 'duedate', top => '842', left => '0', size => '12', bold => 'N', display => 'N', just => 'l' },
  a010 => { table => 'invoices', source => 'invcusterms', alias => 'custerms', top => '842', left => '0', size => '12', bold => 'N', display => 'N', just => 'l' },
  a011 => { table => 'invoices', source => 'invcusref', alias => 'cusref', top => '842', left => '0', size => '12', bold => 'N', display => 'N', just => 'l' },
  a012 => { table => 'companies', source => 'comvatno', alias => 'vatno', top => '842', left => '0', size => '12', bold => 'N', display => 'N', just => 'l' },
  a013 => { table => 'invoices', source => 'invremarks', alias => 'remarks', top => '842', left => '0', size => '12', bold => 'N', display => 'N', just => 'l' },
  a014 => { table => '', source => 'calc', alias => 'nettotal', top => '842', left => '0', size => '12', bold => 'N', display => 'N', just => 'r' },
  a015 => { table => '', source => 'calc', alias => 'vattotal', top => '842', left => '0', size => '12', bold => 'N', display => 'N', just => 'r' },
  a016 => { table => '', source => 'calc', alias => 'invtotal', top => '842', left => '0', size => '12', bold => 'N', display => 'N', just => 'r' },
  a017 => { table => 'companies', source => 'comregno', alias => 'regno', top => '842', left => '0', size => '12', bold => 'N', display => 'N', just => 'l' },
  a018 => { table => 'accounts', source => 'accsort', alias => 'sortcode', top => '842', left => '0', size => '12', bold => 'N', display => 'N', just => 'l' },
  a019 => { table => 'accountss', source => 'accacctno', alias => 'acctno', top => '842', left => '0', size => '12', bold => 'N', display => 'N', just => 'l' },
  a020 => { table => 'invoices', source => 'invitems', alias => 'items', top => '842', left => '0', size => '12', bold => 'N', display => 'N', just => 'l' },
  a021 => { table => '', source => 'calc', alias => 'desc', top => '842', left => '0', size => '12', bold => 'N', display => 'N', just => 'l' },
  a022 => { table => '', source => 'calc', alias => 'qty', top => '842', left => '0', size => '12', bold => 'N', display => 'N', just => 'l' },
  a023 => { table => '', source => 'calc', alias => 'price', top => '842', left => '0', size => '12', bold => 'N', display => 'N', just => 'r' },
  a024 => { table => '', source => 'calc', alias => 'vatrate', top => '842', left => '0', size => '12', bold => 'N', display => 'N', just => 'l' },
  a025 => { table => '', source => 'calc', alias => 'vat', top => '842', left => '0', size => '12', bold => 'N', display => 'N', just => 'r' },
  a026 => { table => '', source => 'calc', alias => 'itmtotal', top => '842', left => '0', size => '12', bold => 'N', display => 'N', just => 'r' },
);

$Data = new CGI;
%FORM = $Data->Vars;

while (( $Key,$Value) = each %FORM) {

#  Remove any bad characters

	$Value =~ tr/\\//d;
	$Value =~ s/\'/\\\'/g;
        $FORM{$Key} = $Value;
warn "$Key = $Value\n";
	if ($Key =~ /^a\d\d\d$/) {
		$Settings{$Key}->{display} = 'Y';
	}
}

#  Get the ACCT from the cookie file (cookie is passed as a parameter)

open(COOKIE,"/projects/tmp/$FORM{cookie}");
while (<COOKIE>) {
	chomp($_);
	($Name,$Value) = split(/\t/,$_);
	$COOKIE->{$Name} = $Value;
	$Cookie{$Name} = $Value;
}
close(COOKIE);
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");
($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});

#  Get the uploaded raw data

$handle = $Data->upload("Filedata");

$Original = "";
while (<$handle>) {
        $Original .= $_;
}

if ($FORM{id} == 0) {

#  Check that there is sufficient upload allowance

	$Layouts = $dbh->prepare("select count(*) from invoice_layouts where acct_id='$COOKIE->{ACCT}'");
	$Layouts->execute;
	@Layout = $Layouts->fetchrow;
	$Layouts->finish;
}

if (@Layout[0] > 4) {

	print<<EOD;
Content-Type: text/plain

Error! - you already have 5 invoice layouts
EOD
}
else {

#  See if this is a new image and, if so, whether he has reached his limit (5)

	$Companies = $dbh->prepare("select comdocsdir from companies where reg_id=$Reg_id and id=$Com_id");
	$Companies->execute;
	$Company = $Companies->fetchrow_hashref;
	$Companies->finish;

	open(IMG,">/projects/fpa_docs/".$Company->{comdocsdir}."/".$FORM{Filename}) || warn "unable to open file\n";
	print IMG $Original;
	close(IMG);

	$Sts = $dbh->do("insert into invoice_layouts (acct_id,layfile) values ('$COOKIE->{ACCT}','/projects/fpa_docs/$Company->{comdocsdir}/$FORM{Filename}')");
	$New_inv_id = $dbh->last_insert_id(undef, undef, qw(invoice_layouts undef));

	while (($Key,$Value) = each %Settings) {
		$Sts = $dbh->do("insert into invoice_layout_items (acct_id,link_id,lifldcode,litable,lisource,lialias,litop,lileft,lisize,libold,lidisplay,lijust) values ('$COOKIE->{ACCT}',$New_inv_id,'$Key','$Value->{table}','$Value->{source}','$Value->{alias}','$Value->{top}','$Value->{left}','$Value->{size}','$Value->{bold}','$Value->{display}','$Value->{just}')");
	}

	print<<EOD;
Content-Type: text/plain

$New_inv_id
EOD
}
$dbh->disconnect;
exit;
