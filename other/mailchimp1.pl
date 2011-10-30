#!/usr/bin/perl

#  Script to send an email address to MailChimp

my $apikey = 'a94017b54d91fe7fe1ac9166712e62c2-us2';
my $listid = 'b4d31d6294';
my $content = "method=listSubscribe&apikey=$apikey&id=$listid&email_address=dougconran\@btinternet.com&merge_vars[FNAME]=Dougie&merge_vars[LNAME]=Conran&double_optin=false&send_welcome=true&output=json";

use LWP::UserAgent;
my $ua = LWP::UserAgent->new;
$ua->agent("MyApp/0.1 ");

# Create a request
my $req = HTTP::Request->new(POST => "http://us2.api.mailchimp.com/1.3/?$content");
$req->content_type('application/x-www-form-urlencoded');
# $req->content($content);

# Pass request to the user agent and get a response back
my $res = $ua->request($req);

# Check the outcome of the response
if ($res->is_success) {
	print $res->content;
}
else {
	print $res->status_line, "\n";
}
exit;
