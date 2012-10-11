#!/usr/bin/perl

$ACCESS_LEVEL = 0;

#  script to display screen for a new invoice

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
        WRAPPER => 'header.tt',
});

$Vars = {
	 ads => $Adverts,
        title => 'Accounts - Upgrade Error',
	cookie => $COOKIE
};

print "Content-Type: text/html\n\n";
$tt->process('upgrade.tt',$Vars);

exit;

