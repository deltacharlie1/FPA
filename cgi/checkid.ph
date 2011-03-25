sub checkid {

#  Header script to check the validity of the user once he has logged in
#  This assumes tht ACCESS_LEVEL has been already been set

@Cookie = split(/\;/,$ENV{HTTP_COOKIE});
foreach (@Cookie) {
	($Name,$Value) = split(/\=/,$_);
	$Name =~ s/^ //g;
	$Value =~ tr/\"//d;
	$Cookie{$Name} = $Value;
}

$Cookie = $Cookie{'fpa-cookie'};

open(COOKIE,"/projects/tmp/$Cookie");
while (<COOKIE>) {
	chomp($_);
	($Name,$Value) = split(/\t/,$_);
	$COOKIE->{$Name} = $Value;
}
close(COOKIE);

#  Check that the cookie email = COOKIE email

unless ($Cookie{'fpa-uid'} && $Cookie{'fpa-uid'} eq $COOKIE->{ID}) {
        print<<EOD;
Content-Type: text/html
Status: 301
Location: /fpa/error.html

EOD
        exit;
}

#  Now check the access level

unless ($COOKIE->{PLAN} >= $ACCESS_LEVEL) {
	print "Content-Type: text/plain\n\n";
	print "I'm sorry, you do not have access to this functionality.  In order to use this feature you will need to upgrade.";

	exit;
}
}
1;
