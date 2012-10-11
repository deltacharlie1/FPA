#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to display Balance Sheet

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

use CGI;
$Data = new CGI;
%FORM = $Data->Vars;

while (( $Key,$Value) = each %FORM) {

#  Remove any bad characters

	$Value =~ tr/\\//d;
	$Value =~ s/\'/\\\'/g;
	$FORM{$Key} = $Value;
}

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");
unless ($COOKIE->{NO_ADS}) {
	require "/usr/local/git/fpa/cgi/display_adverts.ph";
	&display_adverts();
}


#  Save the current filter settings

$Sts = $dbh->do("update tempstacks set f1='$FORM{tbselect}',f2='$FORM{tbstart}',f3='$FORM{tbend}' where acct_id='$COOKIE->{ACCT}' and caller='report'");

#  First get the initial date range

($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});

$Coas = $dbh->prepare("select nomcode,coadesc,coatype,sum(nomamount) as balance from nominals left join coas on (nominals.nomcode=coas.coanominalcode and nominals.acct_id=coas.acct_id) where nominals.acct_id='$COOKIE->{ACCT}' and coareport='Balance Sheet' and nomdate>=str_to_date('$FORM{tbstart}','%d-%b-%y') and nomdate<=str_to_date('$FORM{tbend}','%d-%b-%y')  and coatype=? group by nomcode order by nomcode");
$Coas->execute('Fixed Assets');
$Fixed_Assets = $Coas->fetchall_arrayref({});
$Coas->execute('Current Assets');
$Current_Assets = $Coas->fetchall_arrayref({});
$Coas->execute('Capital');
$Capital = $Coas->fetchall_arrayref({});
$Coas->execute('Current Liabilities');
$Current_Liabilities = $Coas->fetchall_arrayref({});
$Coas->execute('Longterm Liabilities');
$Longterm_Liabilities = $Coas->fetchall_arrayref({});

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
        WRAPPER => 'header.tt',
});

$Vars = {
	 ads => $Adverts,
        title => 'Accounts - Balance Sheet',
	cookie => $COOKIE,
	tbstart => $FORM{tbstart},
	tbend => $FORM{tbend},
	FixedAssets => $Fixed_Assets,
	CurrentAssets => $Current_Assets,
	Capital => $Capital,
	CurrentLiabilities => $Current_Liabilities,
	LongtermLiabilities => $Longterm_Liabilities,
	javascript => '<style>
h3 { font-size: 1.3em;
     font-style: italic;
     font-weight:bold;
}
</style>
<script type="text/javascript">
function print_list() {
   $.get("/cgi-bin/fpa/print_bs.pl",$("form#form1").serialize() ,function(data) {
     $("#main").html(data);
     $("#maintabs").hide();
     $("#printtab").show();
  });
}
</script>'
};

print "Content-Type: text/html\n\n";
$tt->process('balance_sheet.tt',$Vars);

$Coas->finish;
$dbh->disconnect;
exit;

