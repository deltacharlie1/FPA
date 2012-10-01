#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to list invoices

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

$Buffer = $ENV{QUERY_STRING};

@pairs = split(/&/,$Buffer);

foreach $pair (@pairs) {

        ($Name, $Value) = split(/=/, $pair);

        $Value =~ tr/+/ /;
        $Value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C",hex($1))/eg;
        $Value =~ tr/\\\'//d;
        $FORM{$Name} = $Value;
# warn "$Name = $Value\n";
}
#  exit;

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");
unless ($COOKIE->{NO_ADS}) {
	require "/usr/local/git/fpa/cgi/display_adverts.ph";
	&display_adverts();
}


#  Construct the SQL filter

$SQL = "";

if ($FORM{startdate}) {
	$SQL .= "invprintdate >= str_to_date('$FORM{startdate}','%d-%b-%y') and ";
}
if ($FORM{enddate}) {
	$SQL .= "invprintdate <= str_to_date('$FORM{enddate}','%d-%b-%y') and ";
}
if ($FORM{invcusname}) {
	$SQL .= "invcusname like '$FORM{invcusname}%' and ";
}
if ($FORM{invinvoiceno}) {
	$SQL .= "invinvoiceno like '$FORM{invinvoiceno}%' and ";
}
if ($FORM{invcusref}) {
	$SQL .= "invcusref like '$FORM{invcusref}%' and ";
}
if ($FORM{invtype}) {
	$SQL .= "invtype='$FORM{invtype}' and ";
}
if ($FORM{invitem}) {
	$Invitems_selected = "1";
	$SQL .= "itmdesc like '%$FORM{invitem}%' and ";
}
if ($FORM{item_cat}) {
	$Invitems_selected = "1";
	$SQL .= "itmcat like '%$FORM{item_cat}%' and ";
}
if ($FORM{invstatuscode}) {
	$FORM{invstatuscode} =~ tr/V/0/;
	if ($FORM{invstatuscode} == 1) {
		$SQL = "invstatuscode=1 and ";		# because invoices don't get a data until they are finalised
	}
	elsif ($FORM{invstatuscode} > 6) {
		$SQL .= "invstatuscode>6 and ";
	}
	else {
		$SQL .= "invstatuscode='$FORM{invstatuscode}' and ";
	}
}
$SQL .= "invoices.acct_id='$COOKIE->{ACCT}'";

#  Now see if wwe are executing a new query (action = -1) or a continuation of an exisitng one

if ($FORM{action} =~ /S/i) {
	if ($Invitems_selected) {
		$Invoices = $dbh->prepare("select count(*),sum(itmtotal+itmvat) from invoices,items where invoices.id=items.inv_id and invoices.acct_id=items.acct_id and $SQL and invinvoiceno<>'unlisted'");
	}
	else {
		$Invoices = $dbh->prepare("select count(*),sum(invtotal+invvat) from invoices where $SQL and invinvoiceno<>'unlisted'");
	}
        $Invoices->execute;
	($FORM{numrows},$FORM{sumtotal}) = $Invoices->fetchrow;
	$FORM{sumtotal} =~ tr/\-//d;
        $FORM{offset} = 0;
        $FORM{rows} = $FORM{rows} || 24;
}
else {

#  Calculate what is the next batch or records to select

	if ($FORM{action} =~ /^\d+$/ && ($FORM{action} - 1) * $FORM{rows} <= $FORM{numrows}) {		#  Go to a particular page
		$FORM{offset} = ($FORM{action} - 1) * $FORM{rows};
	}
	elsif ($FORM{action} =~ /F/i) {		#  Beginning of record set
		$FORM{offset} = 0;
	}
	elsif ($FORM{action} =~ /N/i && $FORM{offset} + $FORM{rows} <= $FORM{numrows}) {		#  Get the next batch
		$FORM{offset} += $FORM{rows};
	}
	elsif ($FORM{action} =~ /B/i && $FORM{offset} - $FORM{rows} >= 0) {				#  Previous batch
		$FORM{offset} -= $FORM{rows};
	}
	elsif ($FORM{action} =~ /L/i) {		#  Last page of results
		if ($FORM{numrows} % $FORM{rows} > 0) {
			$FORM{offset} = $FORM{numrows} - ($FORM{numrows} % $FORM{rows});
		}
		else {
			$FORM{offset} = $FORM{numrows} - $FORM{rows};
		}
	}
}

if ($Invitems_selected) {
	$Invoices = $dbh->prepare("select cus_id,invoices.id as invid,invinvoiceno,invcusname,invtype,itmdesc as description,date_format(invprintdate,'%d-%b-%y') as printdate,date_format(invduedate,'%d-%b-%y') as duedate,(itmtotal+itmvat) as invamount,invstatus,(invpaid+invpaidvat) as invpaid,to_days(invprintdate) as printdays,to_days(invduedate) as duedays from invoices,items where invoices.id=items.inv_id and invoices.acct_id=items.acct_id and $SQL and invinvoiceno<>'unlisted' order by $FORM{invsort} desc limit $FORM{offset},$FORM{rows}");
}
else {
	$Invoices = $dbh->prepare("select cus_id,invoices.id as invid,invinvoiceno,invcusname,invtype,invdesc as description,date_format(invprintdate,'%d-%b-%y') as printdate,date_format(invduedate,'%d-%b-%y') as duedate,(invtotal+invvat) as invamount,invstatus,(invpaid+invpaidvat) as invpaid,to_days(invprintdate) as printdays,to_days(invduedate) as duedays from invoices where $SQL and invinvoiceno<>'unlisted' order by $FORM{invsort} limit $FORM{offset},$FORM{rows}");
}
$Invoices->execute;

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
});

$Vars = {
	cookie => $COOKIE,
	invoices => $Invoices->fetchall_arrayref({}),
	numrows => $FORM{numrows},
	sumtotal => $FORM{sumtotal},
	offset => $FORM{offset},
	rows => $FORM{rows}
};

print "Content-Type: text/html\n\n";
print "$FORM{numrows}\t$FORM{offset}\t$FORM{rows}\tS\t$FORM{sumtotal}\t";
$tt->process('invrep2.tt',$Vars);

$Invoices->finish;
$dbh->disconnect;
exit;

