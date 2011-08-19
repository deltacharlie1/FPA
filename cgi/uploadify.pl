#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to upload a document or image using jquery uploadify

use CGI;

$Data = new CGI;
%FORM = $Data->Vars;

while (( $Key,$Value) = each %FORM) {

#  Remove any bad characters

	$Value =~ tr/\\//d;
	$Value =~ s/\'/\\\'/g;
        $FORM{$Key} = $Value;
#warn UPL "$Key = $Value\n";
}

#  Get the ACCT from the cookie file (cookie is passed as a parameter)

open(COOKIE,"/projects/tmp/$FORM{cookie}");
while (<COOKIE>) {
	chomp($_);
	($Name,$Value) = split(/\t/,$_);
	$COOKIE->{$Name} = $Value;
	$Cookie{$Name} = $Value;
}
close(COOKIE);
($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});

#  Get the uploaded raw data

$handle = $Data->upload("Filedata");

$Original = "";
while (<$handle>) {
        $Original .= $_;
}

#  Check that there is sufficient upload allowance

unless ($FORM{doc_type} =~ /LOGO/i) {
	if (length($Original) > $COOKIE->{UPLDS}) {
		print<<EOD;
Content-Type: text/plain

File size is larger than your remaining allowance - please upgrade before continuing
EOD
		exit;
	}
}

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");
unless ($COOKIE->{NO_ADS}) {
	require "/usr/local/git/fpa/cgi/display_adverts.ph";
	&display_adverts();
}

use Image::Magick;
$Img = Image::Magick->new;

#  Convert image to an Image Magick object

$status = $Img->BlobToImage($Original);
($width,$height) = $Img->Get('width','height');	#  Get the dimensions

if ($FORM{doc_type} =~ /LOGO/i) {

	if ($width > 144 || $height > 48) {
		if ($width > $height * 3) {
			$W1 = 144;
			$H1 = int(144 * $height / $width);
		}
		else {
			$H1 = 48;
			$W1 = int(48 * $width / $height);
		}
		$Img->Resize(width=>$W1,height=>$H1,blur=>'0');
	}

	$Logo = $Img->ImageToBlob(filename=>$FORM{Filename});

#  ... and save it

	$Companies = $dbh->prepare("update companies set comlogo=? where reg_id=$Reg_id and id=$Com_id");
	$Companies->bind_param(1,$Logo);
	$Companies->execute;

}
elsif ($FORM{Filename} =~ /(pdf|png|jpg|jpeg)$/i) {

#  Create a thumbnail
		
	$W1 = 30;
	$H1 =int(30 * $height / $width);
	$Img->Scale(width=>$W1,height=>$H1);

#  if length > 850 then first crop it

	if ($H1 > 30) {
		$Img->Crop(width=>$W1,height=>30,gravity=>'South');
	}
	$Img->Posterize(levels=>16,dither=>true);
	$Img->Frame(geometry=>'1x1',fill=>'#800000');
}

#  Get invoice details if this is a purchase invoice doc_type

unless ($FORM{desc}) {
	if ($FORM{doc_type} =~ /INV/i) {

		$Invoices = $dbh->prepare("select invcusname,invcusref from invoices where id=$FORM{doc_rec} and acct_id='$COOKIE->{ACCT}'");
		$Invoices->execute;
		@Invoice = $Invoices->fetchrow;
		$Invoices->finish;
		$FORM{desc} = "$Invoice[0] ($Invoice[1])";
	}
	elsif ($FORM{doc_type} =~ /STMT/i) {
		$Stmts = $dbh->prepare("select stastmtno,accname,accacctno from statements left join accounts on (acc_id=accounts.id) where statements.id=$FORM{doc_rec} and statements.acct_id='$COOKIE->{ACCT}'");
		$Stmts->execute;
		@Stmt = $Stmts->fetchrow;
		$Stmts->finish;
		$FORM{desc} = "$Stmt[1] account $Stmt[2] (stmt # $Stmt[0])";
	}
}

unless ($FORM{doc_type} =~ /LOGO/i) {

#  determine the file extension

	$Ext = $FORM{Filename};
	$Ext =~ s/.*\.(.*)$/$1/;

	$Thumb = $Img->ImageToBlob(magick=>'png');

#  Convert Thumb to base64

	use MIME::Base64;
	$Thumb = encode_base64($Thumb);

	$Images = $dbh->prepare("insert into images (link_id,acct_id,imgdoc_type,imgfilename,imgext,imgdesc,imgthumb,imgimage,imgdate_saved) values (?,?,?,?,?,?,?,?,now())");

	$Images->bind_param(1,$FORM{doc_rec});
	$Images->bind_param(2,"$COOKIE->{ACCT}");
	$Images->bind_param(3,"$FORM{doc_type}");
	$Images->bind_param(4,"$FORM{Filename}");
	$Images->bind_param(5,"$Ext");
	$Images->bind_param(6,"$FORM{desc}");
	$Images->bind_param(7,"$Thumb");
#	$Images->bind_param(8,$Original);

	$Images->execute;
	$New_img_id = $dbh->last_insert_id(undef, undef, qw(images undef));

	$Companies = $dbh->prepare("select comdocsdir from companies where reg_id=$Reg_id and id=$Com_id");
	$Companies->execute;
	$Company = $Companies->fetchrow_hashref;
	$Companies->finish;

	open(IMG,">$Company->{comdocsdir}/$FORM{Filename}");
	print IMG $Original;
	close(IMG);

#  Calculate the remaining allowance

	$Allowance = $COOKIE->{UPLDS} - length($Original);
	if ($Allowance < 0) {
		$Allowance = 0;
	}

#  Update the companies record

	$Sts = $dbh->do("update companies set comuplds=$Allowance where reg_id=$Reg_id and id=$Com_id");

#  Update the cookie file

	$Cookie{UPLDS} = $Allowance;

	unlink("/projects/tmp/$FORM{cookie}");

	open(FILE,">/projects/tmp/$FORM{cookie}");
	while(($Key,$Value) = each %Cookie) {
        	print FILE "$Key\t$Value\n";
	}
	close(FILE);

#  Finally write an audit trail remark

	$Sts = $dbh->do("insert into audit_trails (acct_id,link_id,audtype,audaction,audtext,auduser) values ('$COOKIE->{ACCT}',$New_img_id,'display_attach.pl','attachment','Document $FORM{Filename} uploaded','$COOKIE->{USER}')");
}

$dbh->disconnect;
print<<EOD;
Content-Type: text/plain

OK
EOD
exit;
