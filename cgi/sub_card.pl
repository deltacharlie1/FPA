#!/usr/bin/perl

#  Script to record a secure card response.  This is the 'Secure Card URL' and is called by Worldnet
#  response comes in as a get string

$Buffer = $ENV{QUERY_STRING};

@pairs = split(/&/,$Buffer);

foreach $pair (@pairs) {

        ($Name, $Value) = split(/=/, $pair);

        $Value =~ tr/+/ /;
        $Value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C",hex($1))/eg;
        $FORM{$Name} = $Value;
}

use DBI;
$dbh = DBI->connect("DBI:mysql:fpa");

$Membership[0] = 'FreePlus Startup (FREE)';
$Membership[1] = 'FreePlus Standard (&pound;5.00pm)';
$Membership[2] = 'FreePlus Premium (&pound;10.00pm)';

if ($FORM{RESPONSECODE} =~ /A/i) {

#  Get company details to see if we are just updating the card or whether this is a new subscription
#  if comcardref = 'renew' then we are just updating card details, otherwise we go further

	$Companies = $dbh->prepare("select comcardref,comname,comsublevel from companies where commerchantref='$FORM{MERCHANTREF}'");
	$Companies->execute;
	$Company = $Companies->fetchrow_hashref;
	$Companies->finish;

#  Just store the card reference for this Merchantref  (assume hash is ok for now)

	warn "\$Sts = \$dbh->do(\"update companies set comcardref='$FORM{CARDREFERENCE}' where commerchantref='$FORM{MERCHANTREF}'\")\n";
	$Sts = $dbh->do("update companies set comcardref='$FORM{CARDREFERENCE}' where commerchantref='$FORM{MERCHANTREF}'");

	unless ($Company->{comcardref}=~ /renew/) {		#  We are going further so just call sub_subscribe.pl with merchantref

		print<<EOD;
Content-Type: text/hrml
Status: 301
Location: /cgi-bin/fpa/sub_subscribe.pl?$FORM{MERCHANTREF}

EOD
	}
	else {

#  Inform the user that his card update has been successful

		$FORM{CARDEXPIRY} =~ s/(\d\d)(\d\d)/$1\/$2/;

		use Template;
		$tt = Template->new({
			INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib']
		});

		$Vars = { cardtype => $FORM{CARDTYPE},
		          cardnumber => $FORM{MASKEDCARDNUMBER},
		          expiry => $FORM{CARDEXPIRY},
			  company => $Company,
			  membership => $Membership[$Company->{comsublevel}],
			  status => "OK"
		};

		print "Content-Type: text/html\n\n";
		$tt->process('sub_card.tt',$Vars);
	}
}
else {

#  Bad response code, so say why it failed

	use Template;
	$tt = Template->new({
		INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib']
	});

	$Vars = { cardtype => $FORM{RESPONSECODE},
	          cardnumber => $FORM{RESPONSETEXT},
	          expiry => $FORM{CARDEXPIRY},
		  membership => $Membership[$Company->{comsublevel}],
		  status => "Failed"
	};

	print "Content-Type: text/html\n\n";
	$tt->process('sub_card.tt',$Vars);
}
$dbh->disconnect;

exit;

