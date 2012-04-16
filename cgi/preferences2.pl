#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to process registration update details

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});

read(STDIN, $Buffer, $ENV{'CONTENT_LENGTH'});

@pairs = split(/&/,$Buffer);

foreach $pair (@pairs) {

	($Name, $Value) = split(/=/, $pair);

	$Value =~ tr/+/ /;
	$Value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C",hex($1))/eg;
	$Value =~ tr/\\//d;		#  Remove all back slashes
	$Value =~ s/(\'|\")/\\$1/g;
	$FORM{$Name} = $Value;
}

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");

$Prefs = $FORM{memwordcheck}.$FORM{timeout}.$FORM{invpaid}.$FORM{invcat}.$FORM{comuplds}.$FORM{comads};

$Sts = $dbh->do("update registrations set regprefs='$Prefs' where regemail='$COOKIE->{ID}'");

#  Change the cookie file

open(FILE,"</projects/tmp/$COOKIE->{COOKIE}");
while (<FILE>) {
        chomp($_);
        ($Key,$Value) = split(/\t/,$_);
        $DATA{$Key} = $Value;
}
close(FILE);

$DATA{PREFS} = $Prefs;

if ($FORM{comads} =~ /N/i) {
	$DATA{NO_ADS} = "1";
}
else {
	delete($DATA{NO_ADS});
}

unlink("/projects/tmp/$COOKIE->{COOKIE}");

open(FILE,">/projects/tmp/$COOKIE->{COOKIE}");
while(($Key,$Value) = each %DATA) {
        print FILE "$Key\t$Value\n";
}
close(FILE);

print<<EOD;
Content-Type: text/plain

<p>Your preferences have been updated.</p>
EOD

$dbh->disconnect;
exit;
