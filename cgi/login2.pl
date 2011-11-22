#!/usr/bin/perl

#  login script
# print "Content-Type: text/plain\n\n";

read(STDIN, $Buffer, $ENV{'CONTENT_LENGTH'});

@pairs = split(/&/,$Buffer);

foreach $pair (@pairs) {

	($Name, $Value) = split(/=/, $pair);

	$Value =~ tr/+/ /;
	$Value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C",hex($1))/eg;
	$Value =~ tr/\\//d;
	$Value =~ s/(\"|\')/\\$1/g;
	$FORM{$Name} = $Value;
# print "$Name = $Value\n";
}
# exit;

use DBI;
$dbh = DBI->connect("DBI:mysql:fpa");

$Users = $dbh->prepare("select reg_id,regmemword,regmembership,regactive,date_format(date_add(now(), interval 6 month),'%a, %d %b %Y %k:%i:%s GMT'),date_add(now(), interval 6 month),regvisitcount,regprefs from registrations where regemail='$FORM{email}' and regpwd=password('$FORM{pwd}')");
$Users->execute;
@User = $Users->fetchrow;

if ($Users->rows < 1) {
	print<<EOD;
Content-Type: text/html

You have entered an incorrect password, please try again.  If you continue to have difficulty please contact support

EOD
}
elsif (substr($User[7],0,1) =~ /N/i) {
	print<<EOD;
Content-Type: text/plain
Status: 301
Location: /cgi-bin/fpa/login3.pl

EOD
}
else {

#  Check whether this account still needs to be confirmed

	if ($User[3] =~ /P/i) {

		print<<EOD;
Content-Type: text/html

You have not yet confirmed your registration. Please do so first or click here if you would like us to send another registration email.

EOD
	}
	else {

#  If this is the first time logging in then create the Wordpress user.  (We need to do it here so that we
#  can use the clear password).

		if ($Users[6] < 1) {
			$output = `php /usr/local/git/fpa/cgi/add_fpa_user.php $FORM{email} $FORM{pwd} $FORM{email}`;
		}

#  Check whether we need to downgrade

#		if ($User[2] =~ /startup\+/ && $User[5] > $User[6]) {
#			$User[2] = "startup";
#			$Sts = $dbh->do("update accounts set membership_level='startup' where id=$User[0]");
#		}

#  get the mem letters

		my @Nums;
		while (scalar(@Nums) < 3) {

#  Get a new letter position

			$Num = int(rand() * length($User[1]));

#  Check that it does not already exist

			$Good = "1";
			foreach (@Nums) {
				if ($_ == $Num) { $Good = "0"; }
			}
			if ($Good) { push(@Nums,$Num); }
		}

		@Sorted_nums = sort {$a <=> $b} @Nums;

#  Add 1 to each letter position for human indexing

		for $i (0..$#Sorted_nums) {
			$Sorted_nums[$i]++;
		}

		use Template;
		$tt = Template->new({
		        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
		});
		print<<EOD;
Content-Type: text/html
Set-Cookie: fpa-uid=$FORM{email}; path=/; expires=$User[4];

EOD
		$Vars = {
		        title => 'Login - Step 2',
			char1 => $Sorted_nums[0],
			char2 => $Sorted_nums[1],
			char3 => $Sorted_nums[2],
		};
		$tt->process('login2.tt',$Vars);
	}
}
$Users->finish;
$dbh->disconnect;
exit;

