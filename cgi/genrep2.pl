#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to list invoices based on genrealised input from the menu search field

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
my $dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");

#  Construct the SQL filter

$SQL = "";
$Prefix = "";

if ($FORM{searchval} =~ /^\%/) {
	$Prefix = "%";
	$FORM{searchval} =~ tr /\%//d;
}

if ($FORM{searchval} =~ /^\=\d+\.\d\d$/) {
	$FORM{searchval} =~ tr /\=//d;
	$SQL .= "(invtotal='$FORM{searchval}' or invtotal='-$FORM{searchval}') and ";
}
elsif ($FORM{searchval} =~ /^\d+\.\d\d$/) {
	$SQL .= "(invtotal+invvat='$FORM{searchval}' or invtotal+invvat='-$FORM{searchval}') and ";
}
elsif ($FORM{searchval} =~ /^\d+$/) {	#  ie this is an invoice no
	$SQL .= "invinvoiceno like '$Prefix$FORM{searchval}%' and ";
}
elsif ($FORM{searchval} =~ /^\#/) {	#  ie this is an invoice no
	$FORM{searchval} =~ tr /\#//d;
	$SQL .= "invcusref like '$Prefix$FORM{searchval}%' and ";
}
else {
	$SQL .= "invcusname like '$Prefix$FORM{searchval}%' and ";
}
$SQL .= "invoices.acct_id='$COOKIE->{ACCT}'";

#  Now see if wwe are executing a new query (action = -1) or a continuation of an exisitng one

if ($FORM{action} =~ /S/i) {
	$Invoices = $dbh->prepare("select count(*),sum(invtotal+invvat) from invoices where $SQL and invinvoiceno<>'unlisted'");
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

$Invoices = $dbh->prepare("select cus_id,invoices.id as invid,invinvoiceno,invcusname,invtype,invdesc as description,date_format(invprintdate,'%d-%b-%y') as printdate,date_format(invduedate,'%d-%b-%y') as duedate,(invtotal+invvat) as invamount,invstatus,(invpaid+invpaidvat) as invpaid,to_days(invprintdate) as printdays,to_days(invduedate) as duedays from invoices where $SQL and invinvoiceno<>'unlisted' order by invprintdate desc,invinvoiceno desc limit $FORM{offset},$FORM{rows}");
$Invoices->execute;

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
});

$Vars = {
	cookie => $COOKIE,
	invoices => $Invoices->fetchall_arrayref({}),
	GEN => "gen_",
	numrows => $FORM{numrows},
	sumtotal => $FORM{sumtotal},
	offset => $FORM{offset},
	rows => $FORM{rows}
};

print "Content-Type: text/html\n\n";
$tt->process('genrep2.tt',$Vars);

$Invoices->finish;
$dbh->disconnect;
exit;

