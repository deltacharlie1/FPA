#!/usr/bin/perl

#  script to process the contact us input

read(STDIN, $Buffer, $ENV{'CONTENT_LENGTH'});

@pairs = split(/&/,$Buffer);

foreach $pair (@pairs) {

	($Name, $Value) = split(/=/, $pair);

	$Value =~ tr/+/ /;
	$Value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C",hex($1))/eg;
	$FORM{$Name} = $Value;
}

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
		title => 'Contact Us',
		content => $Errs,
		posts => $Posts
	};
	print "Content-Type: text/html\n\n";
	$tt->process('logicdesign.tt',$Vars);

}
else {

#  First send the message to FreePlus Accounts (me ;-)

	open(EMAIL,"| /usr/sbin/sendmail -F \"FreePlus Accounts\" -f \"freeplus\@corunna.com\" -t");

	print EMAIL <<EOD;
To: dconran\@localhost
Subject: $FORM{subject} (for $FORM{recipient})

From $FORM{name} <$FORM{email}>

$FORM{message}
EOD
	close(EMAIL);

	if ($FORM{copy}) {

		open(EMAIL,"| /usr/sbin/sendmail -F \"FreePlus Accounts Auto Responder\" -f \"freeplus\@corunna.com\" -t");

		print EMAIL <<EOD;
To: $FORM{email}
Subject:$FORM{subject}

The following message has been sent to $FORM{recipient} at FreePlus Accounts

----------  Message Start  -----------

$FORM{message}

----------  Message End   ------------
EOD
	}
	close(EMAIL);

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

#  Format the message itself

	$FORM{message} =~ s/\n/<p>/g;
#  Now display a screen

	$Input = sprintf<<EOD;
    <table border="0" cellspacing="0" cellpadding="0" width="600">
      <tr valign=top align=left>
        <td height="10">&nbsp;</td>
      </tr>
    </table>
    <table border=0 cellspacing=0 cellpadding=0>
      <tr>
        <td><h1>Message Sent</h1><p>
The following message has been sent to FreePlus Accounts:<p>
          <table cellpadding="5" style="padding:10px;width:400px;border:1px solid #388a4b;background-color:#eef6f2;">
            <tr>
              <td width="70"><b>From:</b></td>
              <td width="330">$FORM{name}</td>
            </tr>
            <tr>
              <td><b>To:</b></td>
              <td>$FORM{recipient}</td>
            </tr>
            <tr>
              <td><b>Subject:</b></td>
              <td>$FORM{subject}</td>
            </tr>
            <tr>
              <td colspan="2"><b><u>Message</u></b></td>
            </tr>
            <tr>
              <td colspan="2">$FORM{message}</td>
            </tr>
EOD

	if ($FORM{copy}) {
		$Input .= sprintf<<EOD;
            <tr>
              <td height="30" valign="bottom" align="center" colspan="2">(message copied to originator)</td>
            </tr>
EOD
	}
	$Input .= sprintf<<EOD;
          </table>
            <p>Thank you for contacting <b><i>FreePlus Accounts</i></b>
        </td>
    </tr>
 </table>
</body>
</html>
EOD

	$Vars = {
		title => 'Contact Us',
		content => $Input,
		posts => $Posts
	};
	print "Content-Type: text/html\n\n";
	$tt->process('logicdesign.tt',$Vars);
}
exit; 
