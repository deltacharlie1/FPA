#!/usr/bin/perl

#  Script to add affiliate links to adverts table

#  First read through the file and stack each link in a stack dependent on the type of advert (horiz, vert or small)

#  Then run through those stack, starting at different points, and add one link from each into an advert record

use DBI;
$dbh = DBI->connect("DBI:mysql:fpa");
$Sts = $dbh->do("delete from adverts");

$Stack = 1;
$Incr = 0;

while (<>) {

	tr/\r\n//d;

	if (/^</) {
		if ($Stack > 2) {
			push(@Stack3,$_);
#print "$Incr ($Stack) -\t-\t-\tStack 3\n";
		}
		elsif ($Stack > 1) {
			push(@Stack2,$_);
#print "$Incr ($Stack) -\t-\tStack 2\n";
		}
		else {
			push(@Stack1,$_);
#print "$Incr ($Stack) -\tStack 1\n";
		}
		$Stack++;
	}
	if (/^----/) {
		s/^-+\s*(.*)\s+--.*$/$1/;
		print "$_\n";
		$Stack = 1;
		$Incr++;
	}
}

#  Now determine the stack length(s)

$Stack1_len = scalar(@Stack1);
$Stack2_len = scalar(@Stack2);
$Stack3_len = scalar(@Stack3);

$Stack1_index = 0;
$Stack2_index = 4;
$Stack3_index = 9;

foreach $Adv (@Stack1) {
	if ($Stack2_index >= $Stack2_len) {
		$Stack2_index = 0;
	}
	if ($Stack3_index >= $Stack3_len) {
		$Stack3_index = 0;
	}
	$Sts = $dbh->do("insert into adverts (sort,adv1,adv2,adv3) values ($Stack1_index,'$Adv','@Stack2[$Stack2_index]','@Stack3[$Stack3_index]')");
	$Stack1_index++;
	$Stack2_index++;
	$Stack3_index++;
}
$dbh->disconnect;
exit;


