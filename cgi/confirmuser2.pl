#!/usr/bin/perl

#  script to process registration update details

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

use DBI;
$dbh = DBI->connect("DBI:mysql:fpa");

###  Validation

$Errs = "";

#  Email address exists

unless ($FORM{email}) { $Errs .= "<li>No email address</li>\n"; }
if ($FORM{email} && $FORM{email} !~ /^[\w\-\.\+]+\@[a-zA-Z0-9\.\-]+\.[a-zA-z0-9]{2,4}$/) { $Errs .= "<li>Email address in incorrect format</li>\n"; }
if ($FORM{pwd1} && length($FORM{pwd1}) < 6) { $Errs .= "<li>your password is too short</li>\n"; }

#  Check that we have this email address in add_users

$Add_users = $dbh->prepare("select * from add_users where addemail=? and addactivecode=? and addactive='P' limit 1");
$Add_users->execute("$FORM{email}","$FORM{actcode}");
$Add_user = $Add_users->fetchrow_hashref;

unless ($Add_users->rows > 0) {
	$Errs .= "<li>There is no invitation for this email address to access <b><i>FreePlus Account</i></b>.&nbsp;&nbsp;Please contact the owner of the accounts you wish to access.</li>\n";
}

#  From this point on validation differs depending on whether this is a new registration ord not

$Regs = $dbh->prepare("select * from registrations where regemail=?");
$Regs->execute("$FORM{email}");
$Reg = $Regs->fetchrow_hashref;

if ($Regs->rows > 0) {

#  This is a userid for an existing client

	if ($Errs) {
		print<<EOD;
Content-Type: text/plain

You have the following errors:-
<ol>$Errs</ol>
Please correct and resubmit
EOD
	}
	else {

#  insert a reg-coms record

		$Sts = $dbh->do("insert into reg_coms (reg1_id,reg2_id,com_id,comname) values ($Reg->{reg_id},$Add_user->{addreg2_id},$Add_user->{addcom_id},'$Add_user->{addcomname}')");

#  Finally set the addactive flag of add_users to 'C'

		$Sts = $dbh->do("update add_users set addactive='C' where id=$Add_user->{id}");

		print<<EOD;
Content-Type: text/plain

<p>Your new login id has been created, You may now log in by going to <a href="/cgi-bin/fpa/login.pl">http://www.freeplusaccounts.co.uk/login.pl</a></p>
EOD
	}
}
else {

#  This is a new account so new account validation and (maybe) create a new registration

	unless ($FORM{name}) { $Errs .= "<li>Name not entered</li>\n"; }
	if ($FORM{pwd1} && $FORM{pwd1} ne $FORM{pwd2}) { $Errs .= "<li>Passwords do not match</li>\n"; }
	if ($FORM{mem1} && length($FORM{mem1}) < 8) { $Errs .= "<li>Memorable word is too short</li>\n"; }
	if ($FORM{mem1} =~ tr/[a-z][A-Z][0-9] //cd) { $Errs .= "<li>Your memorable word can only contain letters numbers or spaces</li>\n"; }
	if ($FORM{mem1} && $FORM{mem1} ne $FORM{mem2}) { $Errs .= "<li>Memorable Words do not match</li>\n"; }

	if ($Errs) {
		print<<EOD;
Content-Type: text/plain

You have the following errors:-
<ol>$Errs</ol>
Please correct and resubmit
EOD
	}
	else {

#  Add a new registration record

		$Sts = $dbh->do("insert into registrations (regusername,regemail,regpwd,regmemword,regactive,regregdate) values ('$FORM{name}','$FORM{email}',password('$FORM{pwd1}'),'$FORM{mem1}','C',now())");
		$New_reg_id = $dbh->last_insert_id(undef, undef, qw(registrations undef));

#  ... and then insert a reg-coms record

		$Sts = $dbh->do("insert into reg_coms (reg1_id,reg2_id,com_id,comname) values ($New_reg_id,$Add_user->{addreg2_id},$Add_user->{addcom_id},'$Add_user->{addcomname}')");

#  Finally set the addactive flag of add_users to 'C'

		$Sts = $dbh->do("update add_users set addactive='C' where id=$Add_user->{id}");

		print<<EOD;
Content-Type: text/html

OK-Your new login id has been created, You may now log in by going to http://www.freeplusaccounts.co.uk/login.pl.
EOD
	}
}
$Regs->finish; 
$Add_users->finish;
$dbh->disconnect;
exit;
