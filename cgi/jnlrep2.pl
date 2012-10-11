#!/usr/bin/perl

$ACCESS_LEVEL = 3;

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
# exit;

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");
unless ($COOKIE->{NO_ADS}) {
	require "/usr/local/git/fpa/cgi/display_adverts.ph";
	&display_adverts();
}


#  Construct the SQL filter

$SQL = "";

if ($FORM{startdate}) {
	$SQL .= "joudate >= str_to_date('$FORM{startdate}','%d-%b-%y') and ";
}
if ($FORM{enddate}) {
	$SQL .= "joudate <= str_to_date('$FORM{enddate}','%d-%b-%y') and ";
}
if ($FORM{jnlref}) {
	$SQL .= "joujnlno= '$FORM{jnlref}' and ";
}
if ($FORM{jnldesc}) {
	$SQL .= "joudesc like '$FORM{jnldesc}%' and ";
}
$SQL .= "acct_id='$COOKIE->{ACCT}'";

#  Now see if we are executing a new query (action = -1) or a continuation of an exisitng one

if ($FORM{action} =~ /S/i) {

	$Invoices = $dbh->prepare("select count(*) from journals where $SQL");
        $Invoices->execute;
	($FORM{numrows}) = $Invoices->fetchrow;
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

$Invoices = $dbh->prepare("select id,joudesc,joujnlno,date_format(joudate,'%d-%b-%y') as printdate,jouacct,joutype,jouamt,joucount from journals where $SQL order by joudate desc,joujnlno limit $FORM{offset},$FORM{rows}");
$Invoices->execute;

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
});

$Vars = {
	 ads => $Adverts,
	cookie => $COOKIE,
	jnls => $Invoices->fetchall_arrayref({}),
	numrows => $FORM{numrows},
	sumtotal => $FORM{sumtotal},
	offset => $FORM{offset},
	rows => $FORM{rows}
};

print "Content-Type: text/html\n\n";
print "$FORM{numrows}\t$FORM{offset}\t$FORM{rows}\tS\t";
$tt->process('jnlrep2.tt',$Vars);

$Invoices->finish;
$dbh->disconnect;
exit;

