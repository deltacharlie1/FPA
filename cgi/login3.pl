#!/usr/bin/perl

#  login script part 3 - Check memorable word and advance accordingly

read(STDIN, $Buffer, $ENV{'CONTENT_LENGTH'});

# print "Content-Type: text/plain\n\n";

@pairs = split(/&/,$Buffer);

foreach $pair (@pairs) {

	($Name, $Value) = split(/=/, $pair);

	$Value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C",hex($1))/eg;
	$Value =~ tr/ //d;
	$Value =~ tr/\\//d;
	$Value =~ s/(\"|\')/\\$1/g;
	$Value =~ tr/+/ /;
	$FORM{$Name} = $Value;
# print "$Name = $Value\n";
}

@Cookie = split(/\;/,$ENV{HTTP_COOKIE});
foreach (@Cookie) {
        ($Name,$Value) = split(/\=/,$_);
        $Name =~ s/^ //g;
        $Value =~ tr/\"//d;
# print "$Name = $Value\n";
        $Cookie{$Name} = $Value;
}

$Cookie = $Cookie{'fpa-uid'};

use DBI;
$dbh = DBI->connect("DBI:mysql:fpa");
$Regs = $dbh->prepare("select lower(regmemword),reg_id,regemail,regpwd,regmembership,regdefaultmenu,regmenutype,regoptin,regprefs from registrations where regemail='$Cookie'");
$Regs->execute;
@Reg = $Regs->fetchrow;
$Regs->finish;

#  Check the memorable word characters

@Posn = split(/\,/,$FORM{posns});

unless (substr($Reg[8],0,1) =~ /N/i || ($Reg[0] && substr($Reg[0],$Posn[0] - 1,1) eq $FORM{first} && substr($Reg[0],$Posn[1] - 1,1) eq $FORM{second} && substr($Reg[0],$Posn[2] - 1,1) eq $FORM{third})) {

	print<<EOD;
Content-Type: text/plain

You have entered incorrect memorable word characters.&nbsp;&nbsp;Please log in again

EOD
	exit;
}
else {

#  Check to see if there is more than one company for this login

	if ($Cookie =~ /cxrunna\.com/) {
		$Reg_coms = $dbh->prepare("select reg2_id,com_id,comname from reg_coms");
	}
	else {
		$Reg_coms = $dbh->prepare("select reg2_id,com_id,comname from reg_coms where reg1_id=$Reg[1] order by comname");
	}
	$Reg_coms->execute;
	$Companies = $Reg_coms->fetchall_arrayref({});
	$User = $Cookie;
	$User =~ s/^(.*?)\@.*/$1/;
	$Cookie = $User.$$;

#  Create a SHA-1 hash of the cookie

	use Digest;
	$SHA1_hash = Digest->new("SHA-1");
	$SHA1_hash->add($Cookie);
	$Cookie = $SHA1_hash->hexdigest;

	$IP_Addr = $ENV{'REMOTE_ADDR'};
	open(COOKIE,">/projects/tmp/$Cookie");
	print COOKIE "IP\t$IP_Addr\nREG\t$Reg[1]\nID\t$Reg[2]\nPWD\t$Reg[3]\nPLAN\t$Reg[4]\nMENU\t$Reg[6]\nPREFS\t$Reg[8]\n";
	close(COOKIE);

	if ($Reg_coms->rows > 1) {

                use Template;
                $tt = Template->new({
                        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
                });
                print<<EOD;
Content-Type: text/html
Set-Cookie: fpa-cookie=$Cookie; path=/;

EOD
                $Vars = {
                        title => 'Login - Step 3',
			heading => 'Select Company',
			companies => $Companies
                };
                $tt->process('login3.tt',$Vars);
	}
	else {
		print<<EOD;
Content-Type: text/html
Status: 301
Location: /cgi-bin/fpa/login4.pl?0
Set-Cookie: fpa-cookie=$Cookie; path=/;

EOD
	}
	$Reg_coms->finish;
}
$dbh->disconnect;
exit;
