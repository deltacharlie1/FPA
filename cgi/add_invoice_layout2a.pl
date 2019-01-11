#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to upload an invoice layout

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

use CGI;
use DBI;
use URI::Escape;

$Data = new CGI;
%FORM = $Data->Vars;

#  Get the ACCT from the cookie file (cookie is passed as a parameter)

open(COOKIE,"/projects/tmp/$FORM{Session}");
while (<COOKIE>) {
	chomp($_);
	($Name,$Value) = split(/\t/,$_);
	$COOKIE->{$Name} = $Value;
	$Cookie{$Name} = $Value;
}
close(COOKIE);

$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");
($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});

$Layouts = $dbh->prepare("select count(*) from invoice_layouts where acct_id='$COOKIE->{ACCT}'");
$Layouts->execute;
@Layout = $Layouts->fetchrow;
$Layouts->finish;

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
			$v = uri_unescape($v);
			$v =~ s/\+/ /g;
			$PARM{$k} = $v;
			if ($k =~ /id/  && $v==0 && @Layout[0]>20) {
				$Errs .= "<li>You already have the maximum number of layouts</li>\n";
			}
			if ($k =~ /laydesc/i && length($v) < 1) {
				$Errs .= "<li>You must enter a Layout Description</li>\n";
			}
		}
	}
	else {
		if ($Key eq "file" && $Value !~ /.*\.pdf$/i) {
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

#  See if this is a new image and, if so, whether he has reached his limit (5)

	$Companies = $dbh->prepare("select comdocsdir from companies where reg_id=$Reg_id and id=$Com_id");
	$Companies->execute;
	$Company = $Companies->fetchrow_hashref;
	$Companies->finish;
	$Width = 595;
	$Height = 842;

	if ($FORM{file} !~ /pdf$/i) {
		use Image::Magick;
		$Img = Image::Magick->new;
		$status = $Img->BlobToImage($Original);
		($Width,$Height) = $Img->Get('width','height');
		$Original = $Img->ImageToBlob(magick=>'pdf');
	}

	open(IMG,">/projects/fpa_docs/".$Company->{comdocsdir}."/".$FORM{file}) || warn "unable to open file - /projects/fpa_docs/$Company->{comdocsdir}/$FORM{file}\n";
	print IMG $Original;
	close(IMG);

	$PARM{layspace} = $PARM{layspace} || 14;

	$Sts = $dbh->do("insert into invoice_layouts (acct_id,layfile,laydesc,laydateformat,layreversefile,layspace) values ('$COOKIE->{ACCT}','/projects/fpa_docs/$Company->{comdocsdir}/$FORM{file}','$PARM{laydesc}','$PARM{laydateformat}','$PARM{layreversefile}',$PARM{layspace})");
	$New_inv_id = $dbh->last_insert_id(undef, undef, qw(invoice_layouts undef));

#  Otherwise, all is good so just save the file and retuirn success

	print "1";
}

$dbh->disconnect;
exit;
