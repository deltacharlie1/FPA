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
if ($COOKIE->{ACCESS} > 3 || $COOKIE->{PT_LOGO} =~ /1/) {
	$Loadify1 = sprintf<<EOD;
  \$("#comlogo").uploadify({
    "uploader"    : "/js/uploadify.swf",
    "script"      : "/cgi-bin/fpa/uploadify.pl",
    "cancelImg"   : "/js/cancel.png",
    "scriptData"  : {"cookie" : "$COOKIE->{COOKIE}", "doc_type" : "LOGO" },
    "onComplete"  : function() { window.location.reload(true); },
    "buttonText"  : "Select Logo",
    "fileExt"     : "*.jpg;*.png",
    "fileDesc"    : "Image Files (JPG,PNG)",
    "sizeLimit"   : 20480,
    "auto"        : true
  });
EOD
}

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
        WRAPPER => 'header.tt',
});

$Vars = {
        title => 'Accounts - Company Details',
	cookie => $COOKIE,
	focus => 'comname',
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
  $("#comvatscheme").change(function () {
    if (document.getElementById("comvatscheme").value == "N") {
      $(".visible").removeClass("visible").addClass("hidden");
    }
    else {
      $(".hidden").removeClass("hidden").addClass("visible");
    }
    document.getElementById("dialog").innerHTML = "<p>Please note:-<\/p><p>You will need to log out and then log back in before any changes to the VAT scheme will take effect<\/p>";
    $("#dialog").dialog("open");
  });
});
function validate() {
  var errs = "";
  $(".error").removeClass("error");
  $(".mandatory").each(function(i)
    {
      if (/^com/.test(this.name) && this.value.length < 1) {
        if (/vat/.test(this.name)) {
          if (document.getElementById("comvatscheme").value != "N") {
            errs = errs + "<li>Empty " + this.title + "</li>";
            $(this).parent().addClass("error");
            if (errfocus.length < 1) {
              errfocus = this.name;
            }
          }
        }
        else {
          errs = errs + "<li>Empty " + this.title + "</li>";
          $(this).parent().addClass("error");
          if (errfocus.length < 1) {
            errfocus = this.name;
          }
        }
      }
    }
  );
  if (errs.length > 0) {
    errs = "You have the following error(s):-<ol>" + errs + "</ol>Please correct them before re-submitting";
    document.getElementById("dialog").innerHTML = errs;
    $("#dialog").dialog("open");
    return false;
  }
  else {
    $.post("/cgi-bin/fpa/company_details2.pl", $("#form1").serialize(),function(data) {
      if ( ! /^OK/.test(data)) {
        document.getElementById("dialog").innerHTML = data;
        $("#dialog").dialog("open");
      }
      else {
        alert("Details Saved");
        location.href = "/cgi-bin/fpa/" + href[1];
      }
    },"text");
  }
}
function setfocus() {
  eval("document.getElementById(\'" + errfocus + "\').focus();");
}
</script>',
};

print "Content-Type: text/html\n\n";
$tt->process('company_details.tt',$Vars);

$Companies->finish;
$dbh->disconnect;
exit;

