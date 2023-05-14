#!/usr/bin/perl

#  Script to list active customers
#  Because GCL is so stupid we have to get all active mandates and, for each one, get all subscriptions
#  for this mandate and, for each sub, check if it is active and, if active, get the customer details!!!

my $Authorization = 'Bearer live_m2elMSXaTSObKqlTGBGTmy3aMivybF94fROuZCej';
while ( ($key, $value) = each %ENV )
{
  $Headers .=  "key: $key, value: $ENV{$key}\n";
}

use LWP;
use JSON;
$json = JSON->new->allow_nonref;

my $ua = LWP::UserAgent->new;
my $req = HTTP::Request->new(GET => "https://api.gocardless.com/mandates?status=active");

$req->header('Content-Type' => 'application/json');
$req->header('Accept' => 'application/json');
$req->header('Authorization' => $Authorization);
$req->header('GoCardless-Version' => '2015-07-06');

my $res = $ua->request($req);
$mandates_scalar = $json->decode( $res->content );
$Mandates = $mandates_scalar->{mandates};
@Month = ('','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec');
$Count = 0;
$Total_value = 0;
$Total_net = 0;

print<<EOF;
Content-Type: text/html

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en" xml:lang="en">
<head><title>Current Active Customers</title>
<style media="screen" type="text/css">
body {
  font-size: 10pt;
  color: #444444;
  font-family: arial, sans-serif;
}
table {
  border-collapse: collapse;
}
th {
  font-size: 12pt;
  color: #000000;
}
td {
  font-size: 8pt;
}
td,th {
  border: 1px solid #dddddd;
  text-align: left;
  padding: 8px;
}
tr:nth-child(even) {
  background-color: #dddddd;
}
.focus {
  background-color: #c8eccd;
  color: #000;
  cursor: pointer;
  font-weight: bold;
}
.selected {
  background-color: #c8eccd;
  color: #000;
  font-weight: bold;
}
.asc:after {  content: "\\25B2"; }
.desc:after { content: "\\25BC"; }
</style>
<script src="https://ajax.googleapis.com/ajax/libs/jquery/3.2.1/jquery.min.js"></script>
<script type="text/javascript">
\$(document).ready(function() {
  \$('th').each(function(col) {
    \$(this).hover(
    function() { \$(this).addClass('focus'); },
    function() { \$(this).removeClass('focus'); }
  );
    \$(this).click(function() {
      if (\$(this).is('.asc')) {
        \$(this).removeClass('asc');
        \$(this).addClass('desc selected');
        sortOrder = -1;
      }
      else {
        \$(this).addClass('asc selected');
        \$(this).removeClass('desc');
        sortOrder = 1;
      }
      \$(this).siblings().removeClass('asc selected');
      \$(this).siblings().removeClass('desc selected');
      var arrData = \$('table').find('tbody >tr:has(td)').get();
      if (col==2 || col==8) { col++; }
      arrData.sort(function(a, b) {
        var val1 = \$(a).children('td').eq(col).text().toUpperCase();
        var val2 = \$(b).children('td').eq(col).text().toUpperCase();
        if(\$.isNumeric(val1) && \$.isNumeric(val2))
        return sortOrder == 1 ? val1-val2 : val2-val1;
        else
           return (val1 < val2) ? -sortOrder : (val1 > val2) ? sortOrder : 0;
      });
      \$.each(arrData, function(index, row) {
        \$('tbody').append(row);
      });
    });
  });
});
</script>
</head>
<body>
<h1>Current Active Customers</h1>
<table>
  <tr>
    <th></th>
    <th>Customer ID</th>
    <th>Date Joined</th>
    <th style="display:none;">Date Joined</th>
    <th>Name</th>
    <th>Email</th>
    <th>Subscription</th>
    <th>Amount</th>
    <th>net1</th>
    <th>Net2</th>
    <th>Next Due</th>
    <th style="display:none;">Next Due</th>
  </tr>
EOF


for $Mandate ( @{$Mandates} ) {

	my $ua2 = LWP::UserAgent->new;
	my $req2 = HTTP::Request->new(GET => "https://api.gocardless.com/subscriptions?mandate=$Mandate->{id}");

	$req2->header('Content-Type' => 'application/json');
	$req2->header('Accept' => 'application/json');
	$req2->header('Authorization' => $Authorization);
	$req2->header('GoCardless-Version' => '2015-07-06');

	my $res2 = $ua2->request($req2);
	$subs_scalar = $json->decode( $res2->content );
	$Subs = $subs_scalar->{subscriptions};
	for $Sub ( @{$Subs} ) {

		if ($Sub->{status} =~ /active/) {

		        my $ua3 = LWP::UserAgent->new;
        		my $req3 = HTTP::Request->new(GET => "https://api.gocardless.com/customers/$Mandate->{links}->{customer}");

	        	$req3->header('Content-Type' => 'application/json');
	        	$req3->header('Accept' => 'application/json');
		        $req3->header('Authorization' => $Authorization);
        		$req3->header('GoCardless-Version' => '2015-07-06');

		        my $res3 = $ua3->request($req3);
        		$Cus = $json->decode( $res3->content );
			$Count++;
			$Total_value += $Sub->{amount};
			$Net1 = sprintf("%.2f",$Sub->{amount} * 0.99/100);
			$Net2 = sprintf("%.2f",(($Sub->{amount} * 0.99) - 20))/100;
			$Total_net += ($Sub->{amount}*0.99) - 20;
			$Sub->{amount} =~ s/(\d+)(\d\d)/$1\.$2/;

			($Yr,$Mth,$Day) = $Mandate->{created_at} =~ /^\d\d(\d\d)-(\d\d)-(\d\d)T.*/;
			($sYr,$sMth,$sDay) = $Sub->{upcoming_payments}->[0]->{charge_date} =~ /^\d\d(\d\d)-(\d\d)-(\d\d)*/;
			print "<tr><td>$Count</td><td>$Cus->{customers}->{id}</td><td>$Day-$Month[$Mth]-$Yr</td><td style='display:none;'>$Yr$Mth$Day</td><td>$Cus->{customers}->{given_name} $Cus->{customers}->{family_name}</td><td>$Cus->{customers}->{email}</td><td>$Sub->{name}</td><td>$Sub->{amount}</td><td>$Net1</td><td>$Net2</td><td>$sDay-$Month[$sMth]-$sYr</td><td style='display:none;'>$sYr$sMth$sDay</td></tr>\n";
		}
	}
}
$Net_value = $Total_value * 0.99;
$Net_value =~ s/(\d+)(\d\d)/$1\.$2/;
$Total_value =~ s/(\d+)(\d\d)/$1\.$2/;
$Total_net =~ s/(\d+)(\d\d)/$1\.$2/;
$Com1 = $Total_value - $Net_value;
$Com2 = $Total_value - $Total_net;
print "</table></br></br>$Count Customers - Total Monthly Subs : $Total_value (net $Net_value - Commission $Com1) </br>(new net = $Total_net - Commission $Com2)</body></html>\n";
exit;

