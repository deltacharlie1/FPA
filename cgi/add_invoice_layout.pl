#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to display the main cover sheet updating screen

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");
unless ($COOKIE->{NO_ADS}) {
	require "/usr/local/git/fpa/cgi/display_adverts.ph";
	&display_adverts();
}


#  Set up the array of hashes for company year end

$Dates = $dbh->prepare("select date_format(now(),'%m'),date_format(now(),'%Y')");
$Dates->execute;
($This_month,$Year) = $Dates->fetchrow;

$Year++;
$Changed = "";
my @YE;

$Dates = $dbh->prepare("select date_format(last_day(str_to_date(?,'%c')),'%m-%d'),date_format(str_to_date(?,'%c'),'%M')");
for $Month (1..12) {
        if ($Month >= $This_month && ! $Changed) {
                $Changed = "1";
                $Year--;
        }
        $Dates->execute($Month,$Month);
        @Date = $Dates->fetchrow;
        push @YE,  { month => $Date[1], dte => "$Year-$Date[0]" };
}
$Dates->finish;

$Companies = $dbh->prepare("select comname,comaddress,compostcode,comtel,combusiness,comregno,comvatno,comvatscheme,comcontact,comemail,comyearend,comvatduein,comnextsi,comnextpi,comcompleted,comacccompleted,comemailmsg,comstmtmsg,comlogo,comcis,datediff(compt_logo,now()) as pt_logo from companies where reg_id=? and id=?");
$Companies->execute($Reg_id,$Com_id);
$Company = $Companies->fetchrow_hashref;
unless ($Company->{comcis}) { $Company->{comcis} = 'N'; }

$Accts = $dbh->prepare("select acctype,accname,accsort,accacctno,accnewrec from accounts where acct_id='$COOKIE->{ACCT}'");
$Accts->execute;
$Acct = $Accts->fetchall_hashref('acctype');
$Accts->finish;

$Market_Sectors = $dbh->prepare("select id,sector,frsrate from market_sectors");
$Market_Sectors->execute;
$Sectors = $Market_Sectors->fetchall_arrayref({});
$Market_Sectors->finish;

$Invoices = $dbh->prepare("select count(*) as count from invoices where acct_id='$COOKIE->{ACCT}'");
$Invoices->execute;
$Invoice = $Invoices->fetchrow_hashref;
$Invoices->finish;

$Loadify = "";
if ($COOKIE->{ACCESS} > 5) {
	$Loadify1 = sprintf<<EOD;
  \$("#layfile").uploadify({
    "uploader"    : "/js/uploadify.swf",
    "script"      : "/cgi-bin/fpa/uploadify.pl",
    "cancelImg"   : "/js/cancel.png",
    "scriptData"  : {"cookie" : "$COOKIE->{COOKIE}", "doc_type" : "LAYOUT" },
    "buttonText"  : "Select Layout",
    "fileExt"     : "layout*.pdf",
    "fileDesc"    : "Invoice Layout Files (PDF)",
    "sizeLimit"   : 30720,
    "auto"        : false
  });
EOD
}

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
        WRAPPER => 'header.tt',
});

$Vars = {
        title => 'Accounts - Invoice Layouts',
	cookie => $COOKIE,
	focus => 'layname',
	client => $Company,
	sectors => $Sectors,
	yearend => \@YE,
        cur => $Acct->{1200},
        dep => $Acct->{1210},
        card => $Acct->{2010},
	invoice => $Invoice,
        javascript => '<script type="text/javascript"> 
var errfocus = "";
$(document).ready(function(){
'.$Loadify1.'
});
function setfocus() {
  eval("document.getElementById(\'" + errfocus + "\').focus();");
}
</script>',
};

print "Content-Type: text/html\n\n";
$tt->process('add_invoice_layout.tt',$Vars);

$Companies->finish;
$dbh->disconnect;
exit;

