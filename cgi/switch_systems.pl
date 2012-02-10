#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to toggle between the live system and a testbed

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

#  Check to see if we are already in the test system (in which case switch back to the live one)
$ENV{HTTP_COOKIE} = $ENV{HTTP_COOKIE} || "";

@Cookie = split(/\;/,$ENV{HTTP_COOKIE});
foreach (@Cookie) {
	($Name,$Value) = split(/\=/,$_);
	$Name =~ s/^ //g;
	$Value =~ tr/\"//d;
	$Cookie{$Name} = $Value;
}

if ($COOKIE->{ACCT} == '4+3') {
	`mysql fpa2 < /usr/local/git/fpa/other/fpa2.dmp`;
}
else {
open(FILE,"</projects/tmp/$Cookie{'fpa-cookie'}");
while (<FILE>) {
	chomp($_);
	($Key,$Value) = split(/\t/,$_);
	$DATA{$Key} = $Value;
}
close(FILE);

if ($COOKIE->{ACCT} =~ /3\+2/i) {
	$DATA{ACCT} = $DATA{BACCT};
	$DATA{TAG} = $DATA{BTAG};
}
else {
	$DATA{ACCT} = "3+2";
	$DATA{TAG} = "<span style='font-weight:bold;color:#A00000;'>-- Test Company --</span>";
}

unlink("/projects/tmp/$Cookie{'fpa-cookie'}");

open(FILE,">/projects/tmp/$Cookie{'fpa-cookie'}");
while(($Key,$Value) = each %DATA) {
	print FILE "$Key\t$Value\n";
}
close(FILE);
}
print<<EOD;
Content-Type: text/html
Status: 301
Location: /cgi-bin/fpa/dashboard.pl

EOD

exit;
