#!/usr/bin/perl

#  script to process the contact us input

$FORM{email} = "doug.conran\@corunna.com";
$FORM{name} = "Doug Conran";
$FORM{message} = "Trying this again";
$FORM{subject} = "Play it again Sam";
$FORM{recipient} = "tech";

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib']
});
$Posts =  `php /usr/local/git/fpa/cgi/get_posts.php`;
$Posts =~ s/https/http/g;

#  First check that we have a valid email address and a message

$Errs = "";

# use Mail::CheckUser;
# unless (Mail::CheckUser::check_email($FORM{from})) {
# 	$Errs .= "<li>This is not a recognised email address</li>\n";
# }
unless ($FORM{message}) { $Errs .= "<li>There is no text in the Message section</li>\n"; }
unless ($FORM{subject}) { $Errs .= "<li>Please enter a subject heading summarising your reason for contact</li>\n"; }
if ($FORM{subject} =~ /^\d+$/) { $Errs .= "<li>Invalid subject, please be more explicit</li>\n"; }
unless ($FORM{recipient}) { $Errs .= "<li>Please select which department you wish to contact, thank you</li>\n"; }
if ($Errs) {

	$Errs = sprintf<<EOD;
<h1>Errors</h1>
You have the following error(s):-
<ol>$Errs</ol>
Please correct them and re-submit your message.
<p>&nbsp;</p>
<input type="button" name="but1" id="but1" value="Return to Message Screen" onclick="javascript:history.back();"/>
<p>&nbsp;</p>

EOD

	$Vars = {
	 ads => $Adverts,
		title => 'Contact Us',
		content => $Errs,
		posts => $Posts
	};
	print "Content-Type: text/html\n\n";
	$tt->process('logicdesign.tt',$Vars);

}
else {

	unless ($FORM{recipient} =~ /Spam/i || $FORM{email} =~ /yandex/i || $FORM{message} =~ /http/i || $FORM{message} =~ /bitcoin/i) {
#  First send the message to FreePlus Accounts (me ;-)

		if ($FORM{message} =~ /http/i) {
			 $Spam = " ###  SPAM!  ### ";
		}
		$eName = "FreePlus Accounts";
		$eAddr = "freeplus\@corunna.com";

		use DBI;
		$dbh = DBI->connect("DBI:mysql:fpa");
		$Regs = $dbh->prepare("select * from registrations where regemail='$FORM{email}'");
		$Regs->execute;
		if ($Regs->rows > 0) {
			$Reg = $Regs->fetchrow_hashref;
			$Spam = " -- USER --";
			#$eName = $Reg->regusername;
		#	$eAddr = $Reg->regemail;
		}
		
		#open(EMAIL,"| /usr/sbin/sendmail -F \"FreePlus Accounts\" -f \"freeplus\@corunna.com\" -t");
		open(EMAIL,"| /usr/sbin/sendmail -F \"$eName\" -f \"$eAddr\" -t");

		print EMAIL <<EOD;
To: doug.conran49\@googlemail.com
Subject: $FORM{subject} (for $FORM{recipient}$Spam)

From $FORM{name} <$FORM{email}>

$FORM{message}
EOD
		close(EMAIL);
	}
#  re configure the To field

	if ($FORM{recipient} =~ /sales/) {
		$FORM{recipient} = "Sales";
	}
	elsif ($FORM{recipient} =~ /tech/) {
		$FORM{recipient} = "Technical Support";
	}
	elsif ($FORM{recipient} =~ /accts/) {
		$FORM{recipient} = "Accounts Dept";
	}
}
exit; 
