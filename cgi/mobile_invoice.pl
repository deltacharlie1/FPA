#!/usr/bin/perl

#  script to display the main cover sheet updating screen

read(STDIN, $Buffer, $ENV{'CONTENT_LENGTH'});

@pairs = split(/&/,$Buffer);

foreach $pair (@pairs) {

	($Name, $Value) = split(/=/, $pair);

	$Value =~ tr/+/ /;
	$Value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C",hex($1))/eg;
	$FORM{$Name} = $Value;
}

open(EMAIL,"| /usr/sbin/sendmail -t");
print EMAIL <<EOD;
From: Registrations <fparegistrations\@corunna.com>
To: ian\@ilsoft.co.uk
CC: doug.conran\@corunna.com
Subject: Mobile Invoice

QUERY_STRING = $ENV{QUERY_STRING}

-------

Buffer (Post data) = $Buffer

-------

EOD

while (($Key,$Value) = each %FORM) {
	print EMAIL "\t$Key\t=\t$Value\n";
}

close(EMAIL);
exit;
