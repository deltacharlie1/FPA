#!/usr/bin/perl

$ACCESS_LEVEL = 1;

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

@pairs = split(/&/,$ENV{QUERY_STRING});

foreach $pair (@pairs) {

        ($Name, $Value) = split(/=/, $pair);

        $Value =~ tr/+/ /;
        $Value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C",hex($1))/eg;
        $FORM{$Name} = $Value;
}

#  Script to test autosuggest
$Dte = `date +%d-%m-%Y:%H:%M:%S:000`;
chomp($Dte);

$Termid = '2645001';
$Secret = 'CorunnaSecret';

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");

($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});

#  first get the existing comsubtype in case we are updating

$Companies = $dbh->prepare("select comsubtype from companies where reg_id=$Reg_id and id=$Com_id");
$Companies->execute;
$OldCompany = $Companies->fetchrow_hashref;

if ($FORM{sub} =~ /Del/i) {
	$Sts = $dbh->do("update companies set comsublevel='$FORM{sub}' where reg_id=$Reg_id and id=$Com_id");
}
elsif ($FORM{sub} =~ /new/) {
	$Sts = $dbh->do("update companies set comcardref='$FORM{sub}' where reg_id=$Reg_id and id=$Com_id");
}
else {
	$Sts = $dbh->do("update companies set comsubtype='$FORM{sub}' where reg_id=$Reg_id and id=$Com_id");
}

$Companies = $dbh->prepare("select commerchantref,comcardref,comsubtype from companies where reg_id=$Reg_id and id=$Com_id");
$Companies->execute;
$Company = $Companies->fetchrow_hashref;
$Companies->finish;

use Digest;

unless ($Company->{commerchantref}) {
	$Merchref = Digest->new("MD5");
	$Merchref->add($$.$COOKIE->{ID});
	$Company->{commerchantref} = $Merchref->hexdigest;
	$Sts = $dbh->do("update companies set commerchantref='$Company->{commerchantref}' where reg_id=$Reg_id and id=$Com_id");
}

$dbh->disconnect;

$Hash = Digest->new("MD5");
if ($Company->{comcardref}) {
	$Hash->add($Termid.$Company->{commerchantref}.$Dte.'update'.$Secret);
	$Hash_text = $Hash->hexdigest;
	$JSON = "{ \"action\": \"update\", \"termid\": \"$Termid\", \"merchref\": \"$Company->{commerchantref}\", \"dte\": \"$Dte\", \"hash\": \"$Hash_text\", \"oldsubtype\": \"$OldCompany->{comsubtype}\" }";
}
else {
	$Hash->add($Termid.$Company->{commerchantref}.$Dte.'register'.$Secret);
	$Hash_text = $Hash->hexdigest;
	$JSON = "{ \"action\": \"register\", \"termid\": \"$Termid\", \"merchref\": \"$Company->{commerchantref}\", \"dte\": \"$Dte\", \"hash\": \"$Hash_text\", \"oldsubtype\": \"$OldCompany->{comsubtype}\" }";
}

print "Content-Type: text/plain\n\n";
print "[ $JSON ]";
exit;
