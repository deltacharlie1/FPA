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

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
        WRAPPER => 'header.tt',
});

$Vars = {
        title => 'Accounts - Invoice Layouts',
	cookie => $COOKIE,
	focus => 'a001',
        javascript => '<script type="text/javascript"> 
var errfocus = "";
var uploadparms = "doug";
$(document).ready(function(){
  $("#layfile").uploadify({
    "uploader"    : "/js/uploadify.swf",
    "script"      : "/cgi-bin/fpa/add_invoice_layout2.pl",
    "cancelImg"   : "/js/cancel.png",
    "scriptData"  : {"cookie" : "'.$COOKIE->{COOKIE}.'", "doc_type" : "LAYOUT" },
    "buttonText"  : "Select Layout",
    "fileExt"     : "layout*.pdf",
    "fileDesc"    : "Invoice Layout Files (PDF)",
    "sizeLimit"   : 30720,
    "auto"        : false,
    "onComplete" : function(a,b,c,d,e) {
                     if (/Error/i.test(d)) {
                       alert(d);
                     }
                     else {
                       location.href="/cgi-bin/fpa/layout_invoice_layout.pl?" + d;
                     }
                   },
    "removeCompleted" : true
  });
});
function setfocus() {
  eval("document.getElementById(\'" + errfocus + "\').focus();");
}
</script>',
};

print "Content-Type: text/html\n\n";
$tt->process('add_invoice_layout.tt',$Vars);

$dbh->disconnect;
exit;

