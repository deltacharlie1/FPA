#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to update Company Details

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");
unless ($COOKIE->{NO_ADS}) {
	require "/usr/local/git/fpa/cgi/display_adverts.ph";
	&display_adverts();
}

($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});

$Companies = $dbh->prepare("select comdocsdir from companies where reg_id=$Reg_id and id=$Com_id");
$Companies->execute;
$Company = $Companies->fetchrow_hashref;
$Companies->finish;

#  Get the image

$Images = $dbh->prepare("select imgimage,imgext,imgfilename from images where acct_id='$COOKIE->{ACCT}' and id=$ENV{QUERY_STRING}");
$Images->execute;
@Image = $Images->fetchrow;
$Images->finish;
$dbh->disconnect;

open(IMG,"</projects/fpa_docs".$Company->{comdocsdir}."/".$Image[2]);
while(<IMG>) {
	$Image[0] .= $_;
}
close(IMG);

if ($Image[1] =~ /pdf/i) {
	print "Content-Type: application/pdf\n";
	print "Content-Disposition: inline; filename=$Image[2]\n\n";
	print $Image[0];
}
else {
	print "Content-Type: image/$Image[1]\n\n";
	print $Image[0];
}
exit;
