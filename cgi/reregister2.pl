#!/usr/bin/perl

$ACCESS_LEVEL = 0;

#  script to process registration update details

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});

read(STDIN, $Buffer, $ENV{'CONTENT_LENGTH'});

@pairs = split(/&/,$Buffer);

foreach $pair (@pairs) {

	($Name, $Value) = split(/=/, $pair);

	$Value =~ tr/+/ /;
	$Value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C",hex($1))/eg;
	$Value =~ tr/\\//d;		#  Remove all back slashes
	$Value =~ s/(\'|\")/\\$1/g;
	$FORM{$Name} = $Value;
}

###  Validation

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");

$Errs = "";

#  Email address exists


#  Check to see if we already have this email address

$Regs = $dbh->prepare("select * from registrations where regemail='$FORM{email}' and reg_id <> $Reg_id");
$Regs->execute;
if ($Regs->rows > 0) {
	$Errs .= "<li>The email address is already being used!&nbsp;&nbsp;Please enter a different one or contact Support Administration</li>\n";
}

if ($Errs) {
	print<<EOD;
Content-Type: text/plain

Errors!

$Errs
EOD
}
else {

	$Regs = $dbh->prepare("select regmembership from registrations where reg_id=$Reg_id and regemail='$FORM{email}'");
	$Regs->execute();
	@Reg = $Regs->fetchrow;

	$SQL = "";
	if ($FORM{optin} =~ /N/i) {
		$SQL .= "regmembership='0',";
	}
	elsif ($FORM{optin} =~ /Y/ && $Reg[0] =~ /0/) {
		$SQL .= "regmembership='1',";
	}
	
	if ($FORM{pwd1}) {
		$SQL .= "regpwd=password('$FORM{pwd1}'),";
	}
	if ($FORM{mem1}) {
		$SQL .= "regmemword='$FORM{mem1}',";
	}

	$Sts = $dbh->do("update registrations set $SQL regusername='$FORM{name}',regemail='$FORM{email}',regmenutype='$FORM{regmenu}',regoptin='$FORM{optin}' where reg_id=$Reg_id");

#  Check to see if the membership level has changed

	$Regs = $dbh->prepare("select regmembership from registrations where reg_id=$Reg_id");
	$Regs->execute;
	($Regmembership) = $Regs->fetchrow;

	if ($Regmembership != $FORM{plan}) {
		$Msg = "Thank you for electing to upgrade your membership.&nbsp;&nbsp;Our paid-for services are still under development and we will inform you as soon as they have been tested and are ready for use.";
	}

	print<<EOD;
Content-Type: text/plain

<p>Your details have been updated, any password changes will take effect the next time you log in.</p>
<p>$Msg</p>
EOD
}
$Regs->finish; 
$dbh->disconnect;
exit;
