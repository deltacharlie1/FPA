#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to add a reminder

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

use CGI;
use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");

$Data = new CGI;
%FORM = $Data->Vars;

while (( $Key,$Value) = each %FORM) {

#  Remove any bad characters

	$Value =~ tr/\\//d;
	$Value =~ s/\'/\\\'/g;
	$FORM{$Key} = $Value;
}

#  Then just save the record

$Sts = $dbh->do("insert into comments (comtext,comuser,comgrade) values ('$FORM{comtext}','$COOKIE->{ID}','$FORM{comgrade}')");
$New_txn_id = $dbh->last_insert_id(undef, undef, qw(comments undef));

#  and send an email to me

open(EMAIL,"| /usr/sbin/sendmail -t");
print EMAIL <<EOD;
From: FreePlus <doug.conran49\@googlemail.com>
To: doug.conran49\@googlemail.com
Subject: A FreePlus Comment has been added

The following comment has been added by $COOKIE->{ID}

$FORM{comtext}

Comment ID is:  $New_txn_id

EOD
                close(EMAIL);

print<<EOD;
Content-Type: text/plain

	Your Comment<p>$FORM{comtext}</p> has been added
EOD
$dbh->disconnect;
exit;
