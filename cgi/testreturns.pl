#!/usr/bin/perl

$Sub = "FreePlus Standard";
$Amt = "£6.00 per month";
$First = "24th May 2017";
$Recs = " 18th";

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
	WRAPPER => 'header.tt'
        });

$Vars = {
	success => '0',
	subtitle => $Sub,
	subamt => $Amt,
	firstpayment => $First,
	recpayment => $Recs,
	  javascript => '<style type="text/css">
.subblock { background-color: #dee5d2; }
</style>'
};

print "Content-Type: text/html\n\n";
$tt->process('testreturns.tt',$Vars);
exit;

