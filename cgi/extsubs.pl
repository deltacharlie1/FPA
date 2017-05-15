#!/usr/bin/perl

$Data = "";
while (<>) {
	$Data .= $_;
}
$Total = 0;

while ($Data =~ s/<subscription>(.*?)<\/subscription>/&Ext($1)/eigs) {
}

print "\n\nTotal = $Total\n";
exit;

sub Ext {
	$Sb = shift;

	$Sb =~ s/.*<status>(.*)<\/status>.*<amount>(.*)<\/amount>.*<next-interval-start>(.*?)T.*<user-id>(.*)<\/user-id>.*/$3 $2 $4/is;
	if ($1 !~ /cancelled/) {
		print $Sb."\n";
		$Total += $2;
	}
	return "";
}
