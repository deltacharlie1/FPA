#!/usr/bin/perl

$XML = '<RESPONSECODE>A</RESPONSECODE><RESPONSETEXT>Approved</RESPONSETEXT><APPROVALCODE>675673</APPROVALCODE><DATETIME>22-01-2012:22:41:34:000</DATETIME><HASHedbernmtyrw</HASH>';

($Code,$Text,$Auth) = ($XML =~ /^.*?CODE>(\w+)<\/RESPONSE.*?TEXT>(\w+)<\/RESPONSETEXT.*?CODE>(.*)?<\/APP.*$/);

print "Code = $Code\nText = $Text\nAuth = $Auth\n";

exit;

