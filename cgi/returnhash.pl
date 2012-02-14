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

open(XML,'</usr/local/git/fpa/other/cashflows') || warn "Could not open cashflos file\n";
@Xmlstr = <XML>;
close(XML);

($Termid,$Secret,$URL) = @Xmlstr;
chomp($Termid);
chomp($Secret);
chomp($URL);

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");

($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});

#  gett the current setup

$Companies = $dbh->prepare("select comsubtype,commerchantref,comcardref,comsubref from companies where reg_id=$Reg_id and id=$Com_id");
$Companies->execute;
$Company = $Companies->fetchrow_hashref;

if ($FORM{action} =~ /cancel/i) {
	$Sts = $dbh->do("update companies set comsubtype='cancel' where reg_id=$Reg_id and id=$Com_id");
}
#elsif ($FORM{action} =~ /card/) {
#	$Sts = $dbh->do("update companies set comcardref='card' where reg_id=$Reg_id and id=$Com_id");
#}
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
	$Sts = $dbh->do("update companies set commerchantref='$Company->{commerchantref}',comdocsdir='$Company->{commerchantref}' where reg_id=$Reg_id and id=$Com_id");
	mkdir("/projects/fpa_docs/".$Company->{commerchantref);
}

$dbh->disconnect;

$Hash = Digest->new("MD5");
if ($Company->{comcardref}) {
	$Hash->add($Termid.$Company->{commerchantref}.$Dte.'update'.$Secret);
	$Hash_text = $Hash->hexdigest;
	$JSON = "{ \"action\": \"update\", \"termid\": \"$Termid\", \"merchref\": \"$Company->{commerchantref}\", \"dte\": \"$Dte\", \"hash\": \"$Hash_text\", \"oldsubtype\": \"$Company->{comsubtype}\" }";
}
else {
	$Hash->add($Termid.$Company->{commerchantref}.$Dte.'register'.$Secret);
	$Hash_text = $Hash->hexdigest;
	$JSON = "{ \"action\": \"register\", \"termid\": \"$Termid\", \"merchref\": \"$Company->{commerchantref}\", \"dte\": \"$Dte\", \"hash\": \"$Hash_text\", \"oldsubtype\": \"$Company->{comsubtype}\" }";
}

print "Content-Type: text/plain\n\n";
print "[ $JSON ]";
exit;
