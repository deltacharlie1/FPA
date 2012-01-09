#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to change nominal codes

#  1.  Get Nominals record
#
#  If nomtype = 'S' (invoice) then
#    a  -  change invcoa
#    b  -  get inv_txn record using link_id = inv_id
#    c  -  get vataccrual record from inv_txns.id = acrtxn_id (or acrtxn_id = invoice.id for Standard accountning)
#    d  -  change acrnominalcode
#
#  Else if nomtype = 'T' (txn) then
#    a  -  get txn
#    b  -  get inv_txn using txn.id = txn_id
#    c  -  get invoice from inv_id = invoices.id
#    d  -  change invcoa
#    e  -  get vataccrual record from inv_txns.id = acrtxn_id
#    f  -  change acrnominalcode
#
#  reduce old coa amount
#  increase new coa amount


use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

use CGI;
use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");

#  Set up sql prepares

$Coas = $dbh->prepare("select id from coas where acct_id='$COOKIE->{ACCT}' and coanominalcode=?");
$Noms = $dbh->prepare("select nomtype,link_id,nomcode,nomamount from nominals where acct_id='$COOKIE->{ACCT}' and id=?");
$Inv_ITs = $dbh->prepare("select id,txn_id from inv_txns where acct_id='$COOKIE->{ACCT}' and inv_id=?");
$Txn_ITs = $dbh->prepare("select id,inv_id from inv_txns where acct_id='$COOKIE->{ACCT}' and txn_id=?");

$Data = new CGI;
%FORM = $Data->Vars;

#  now go through each change

while (( $Key,$Value) = each %FORM) {

#  Remove any bad characters

	$Value =~ tr/\\//d;
	$Value =~ s/\'/\\\'/g;
	$Key =~ s/^nom//;

	if ($Value) {

#  Check to see that we have this nominal account

		$Coas->execute("$Value");

		if ($Coas->rows > 0) {

			$Coa = $Coas->fetchrow_hashref;
	
#  Get the nominal code to see what type it is

			$Noms->execute("$Key");
			$Nom = $Noms->fetchrow_hashref;
			$Sts = $dbh->do("update nominals set nomcode='$Value' where acct_id='$COOKIE->{ACCT}' and id=$Key");

			if ($Nom->{nomtype} =~ /S/i) {		#  Invoice type nominal

#  change the invoice invcoa

				$Sts = $dbh->do("update invoices set invcoa='$Value' where acct_id='$COOKIE->{ACCT}' and id=$Nom->{link_id}");

#  Get the inv_txn record for the inv_txn id for vat accruals

				$Inv_ITs->execute("$Nom->{link_id}");
				$aIT = $Inv_ITs->fetchall_arrayref({});

				foreach $IT (@$aIT) {

#  update the vataccrual

					$Sts = $dbh->do("update vataccruals set acrnominalcode='$Value' where acct_id='$COOKIE->{ACCT}' and acrtxn_id=$IT->{id}");
				}
			}
			elsif ($Nom->{nomtype} =~ /T/i) {	# Txn type nominal

#  get the inv_txn so that we can get the invoice id

				$Txn_ITs->execute("$Nom->{link_id}");
				$aIT = $Txn_ITs->fetchall_arrayref({});

				foreach $IT (@$aIT) {

#  update the invoice

					$Sts = $dbh->do("update invoices set invcoa='$Value' where acct_id='$COOKIE->{ACCT}' and id=$IT->{inv_id}");

#  update the vataccrual

					$Sts = $dbh->do("update vataccruals set acrnominalcode='$Value' where acct_id='$COOKIE->{ACCT}' and acrtxn_id=$IT->{id}");
				}
			}

#  Finally update the relevant coa balances

#  strip off any minus sign

			$Nom->{nomamount} =~ tr/-//d;

#  Add to the new nominal code

			$Sts = $dbh->do("update coas set coabalance=coabalance+'$Nom->{nomamount}' where acct_id='$COOKIE->{ACCT}' and id=$Coa->{id}");
			$Sts = $dbh->do("update coas set coabalance=coabalance-'$Nom->{nomamount}' where acct_id='$COOKIE->{ACCT}' and coanominalcode='$Nom->{nomcode}'");

		}
	}
}

print<<EOD;
Content-Type: text/html
Status: 301
Location: /cgi-bin/fpa/reassign_nominals.pl

EOD
$Coas->finish;
$Noms->finish;
$Inv_ITs->finish;
$Txn_ITs->finish;
$dbh->disconnect;
exit;
