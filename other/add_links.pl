#!/usr/bin/perl

#  Script to add affiliate links to adverts table

use DBI;
$dbh = DBI->connect("DBI:mysql:fpa");

$First_link = "1";
$Adv1 = "";
$Adv2 = "";
$Adv3 = "";

$Sort = 0;

$Incr = 0;

while (<>) {

	tr/\r\n//d;
$Incr++;

	if (/^---/) {		#  New affiliate
		unless ($First_link) {
			$Sort++;

#  Add to table
			$Sts = $dbh->do("insert into adverts (sort,adv1,adv2,adv3) values ($Sort,'$Adv1','$Adv2','$Adv3')");

			$Adv1 = "";
			$Adv2 = "";
			$Adv3 = "";
		}
		$First_link = "";
	}

	if (/^</) {

		unless ($Adv1) {
			$Adv1 = $_;
		}
		else {
			unless ($Adv2) {
				$Adv2 = $_;
			}
			else {
				$Adv3 = $_;
			}
		}
	}
}
exit;

