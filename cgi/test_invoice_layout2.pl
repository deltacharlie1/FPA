#!/usr/bin/perl

use CGI;
use URI::Escape;
$Data = new CGI;

%FORM = $Data->Vars;
$Errs = "";


$handle = $Data->upload("file");

$Errs .= "<ol>";
$Original = "";
while (<$handle>) {
        $Original .= $_;
}
if (length($Original) < 1 || length($Original)>61440) {
	$Errs .=  "<li>The Layout file size must be between 0k and 60k</li>\n";
}

while (( $Key,$Value) = each %FORM) {

#  Remove any bad characters

	if ($Key =~ /form/i) {
		@Parms = split(/\&/,$Value);
		foreach $Parm (@Parms) {
			($k,$v) = split(/\=/,$Parm);
			if ($k =~ /laydesc/i && length($v) < 1) {
				$Errs .= "<li>You must enter a Layout Description</li>\n";
			}
		}
	}
	else {
		if ($Key eq "file" && $Value !~ /\.pdf$/i) {
			$Errs .= "<li>The Layout file must be in PDF format</li>\n";
		}
	}
}

if (length($Errs) > 5) {
	print<<EOD;
Content-Type: text/html

<html>
<head>
<title>Errors</title>
</head>
<body>
<p>
<h2><center>You have Errors</h2></center>
$Errs
</ol>
<p><center><input type="button" name="pl1" id="pl1" value="Click to Refresh" onclick="location.reload(true);"/></center>
</body>
</html>
EOD
}
else {
	print "1";
}

exit;
