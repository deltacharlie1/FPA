#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to list documents

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

$Buffer = $ENV{QUERY_STRING};

@pairs = split(/&/,$Buffer);

# print "Content-Type: text/plain\n\n";

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

#  Construct the SQL filter

$SQL = "";

if ($FORM{startdate}) {
	$SQL .= "imgdate_saved >= str_to_date('$FORM{startdate}','%d-%b-%y') and ";
}
if ($FORM{enddate}) {
	$SQL .= "imgdate_saved <= str_to_date('$FORM{enddate}','%d-%b-%y') and ";
}
if ($FORM{imgfilename}) {
	$SQL .= "imgfilename like '$FORM{imgfilename}%' and ";
}
if ($FORM{imgdoc_type}) {
	$SQL .= "imgdoc_type='$FORM{imgdoc_type}' and ";
}
if ($FORM{imgdesc}) {
	$SQL .= "imgdesc like '%$FORM{imgdesc}%' and ";
}
$SQL .= "acct_id='$COOKIE->{ACCT}'";

#  Now see if we are executing a new query (action = -1) or a continuation of an exisitng one

if ($FORM{action} =~ /S/i) {

	$Images = $dbh->prepare("select count(*) from images where $SQL");
	$Images->execute;
	($FORM{numrows}) = $Images->fetchrow;
        $FORM{offset} = 0;
        $FORM{rows} = $FORM{rows} || 10;
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

$Images = $dbh->prepare("select id,imgfilename,imgext,imgdoc_type,imgdesc,imgthumb,date_format(imgdate_saved,'%d-%b-%y') as imgdate from images where $SQL order by imgdate_saved desc limit $FORM{offset},$FORM{rows}");
$Images->execute;

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
});

$Vars = {
	 ads => $Adverts,
	cookie => $COOKIE,
	docs => $Images->fetchall_arrayref({}),
	numrows => $FORM{numrows},
	offset => $FORM{offset},
	rows => $FORM{rows}
};

print "Content-Type: text/html\n\n";
print "$FORM{numrows}\t$FORM{offset}\t$FORM{rows}\tS\t";
$tt->process('docsrep2.tt',$Vars);

$Images->finish;
$dbh->disconnect;
exit;

