#!/usr/bin/perl

%Settings = (
  a001 => { table => 'invoices', source => 'invtype', alias => 'invtype', top => '842', left => '0', size => '12', bold => 'N', display => 'N', just => 'l' },
  a002 => { table => 'companies', source => 'concat(comname,"\n",comaddress,"  ,compostcode)', alias => 'myaddress', top => '842', left => '0', size => '12', bold => 'N', display => 'N', just => 'l' },
  a003 => { table => 'companies', source => 'comtel', alias => 'mytel', top => '842', left => '0', size => '12', bold => 'N', display => 'N', just => 'l' },
  a004 => { table => 'companies', source => 'comemail', alias => 'myemail', top => '842', left => '0', size => '12', bold => 'N', display => 'N', just => 'l' },
  a005 => { table => 'invoices', source => 'concat(invcusname,"\n",invcusaddr"  ",invcuspostcode)', alias => 'cusaddress', top => '842', left => '0', size => '12', bold => 'N', display => 'N', just => 'l' },
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

while (($Key,$Value) = each %Settings) {
	print $Key." - ".$Value->{table}."\t".$Settings{$Key}->{source}."\t".$Settings{$Key}->{alias}."\n";
}

exit;
