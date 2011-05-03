#!/usr/bin/perl

#  The default initial menu displayed at first login

$ACCESS_LEVEL = 0;

# use Checkid;

use Checkid;
$COOKIE =  &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib']
});

$Vars = {
        title => 'Design Template'
};


print "Content-Type: text/html\n\n";

$tt->process('testit.tt',$Vars);
exit;

