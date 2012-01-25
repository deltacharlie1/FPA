#!/usr/bin/perl

$ACCESS_LEVEL = 0;

#  script to display the help tutorials

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
	WRAPPER => 'help_header.tt'
        });

$Vars = { cookie => $COOKIE,
	  title => 'Video Tutorials'
};

print "Content-Type: text/html\n\n";
$tt->process('tutorials.tt',$Vars);
exit;

