#!/usr/bin/perl

#  Script to change an errorneously entered nominal code.  Called from coa_drill_down

use CGI;

warn "Calling change nomcode\n";

$ACCESS_LEVEL = 1;

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

$Data = new CGI;
%FORM = $Data->Vars;

while (( $Key,$Value) = each %FORM) {

#  Remove any bad characters

        $Value =~ tr/\\//d;
        $Value =~ s/\'/\\\'/g;
        $FORM{$Key} = $Value;
}

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");

#  First get the amount to be re-directed

$Noms = $dbh->prepare("select nomcode,nomamount from nominals where acct_id='$COOKIE->{ACCT}' and id=$FORM{id}");
$Noms->execute;
@Nom = $Noms->fetchrow;
$Noms->finish;

#  Deduct that amoiunt from therelevant COA

$Sts = $dbh->do("update coas set coabalance=coabalance-'$Nom[1]' where acct_id='$COOKIE->{ACCT}' and coanominalcode='$Nom[0]'");

#  Now add that amount to the new COA

$Sts = $dbh->do("update coas set coabalance=coabalance+'$Nom[1]' where acct_id='$COOKIE->{ACCT}' and coanominalcode='$FORM{newcode}'");

#  Change the transaction record date#  and finally change the nominal code of the original entry

$Sts = $dbh->do("update nominals set nomcode='$FORM{newcode}' where acct_id='$COOKIE->{ACCT}' and id=$FORM{id}");

#  Then write an audit trail remark


$Sts = $dbh->do("insert into audit_trails (acct_id,link_id,audtype,audaction,audtext,auduser) values ('$COOKIE->{ACCT}',$FORM{id},'','change','Nominal code change from $Nom[0] to $FORM{newcode}','$COOKIE->{USER}')");

print<<EOD;
Content-Type:text/plain

OK-
EOD
$dbh->disconnect;
exit;
