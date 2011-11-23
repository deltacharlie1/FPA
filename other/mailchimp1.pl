#!/usr/bin/perl

#  Script to send an email address to MailChimp

my $apikey = 'a94017b54d91fe7fe1ac9166712e62c2-us2';

my $news_letter_id = 'b4d31d6294';
my $bookkeepers_id = 'eb281d3b70';
my $list_id = "";
my $SQL = "";

if ($ARGV[0] =~ /news/i) {
	$list_id = $news_letter_id;
	$SQL .= " and reg_id>5";
}
elsif ($ARGV[0] =~ /book/i) {
	$list_id = $bookkeepers_id;
	$SQL .= " and regreferer like '%icb%'";
}
else {
	print<<EOD;

You must specify the list to use.  The syntax is:-

  ./mailchimp1.pl <list>

EOD
	exit;
}

use DBI;
use LWP::UserAgent;

$dbh = DBI->connect("DBI:mysql:fpa");
$Regs = $dbh->prepare("select regemail,regusername from registrations where regoptin='Y' $SQL");
$Regs->execute;
while (@Reg = $Regs->fetchrow) {
	$Reg[1] =~ tr/ /+/;
#	print "$Reg[0]\t\t-\t\t$Reg[1]\n";
	my $content = "method=listSubscribe&apikey=$apikey&id=$list_id&email_address=$Reg[0]&merge_vars[FNAME]=$Reg[1]&double_optin=false&send_welcome=false&output=json";

	my $ua = LWP::UserAgent->new;
	$ua->agent("FPA/0.1 ");

# Create a request
	my $req = HTTP::Request->new(POST => "http://us2.api.mailchimp.com/1.3/?$content");
	$req->content_type('application/x-www-form-urlencoded');
# $req->content($content);

# Pass request to the user agent and get a response back
	my $res = $ua->request($req);

# Check the outcome of the response

	if ($res->is_success) {
		print "Added - $Reg[0]\n";
	}
	else {
		print "Not Added - $Reg[0]\n";
	}
}
$Regs->finish;
$dbh->disconnect;

exit;
