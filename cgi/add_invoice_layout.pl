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

$Revs = $dbh->prepare("select id,laydesc from invoice_layouts where acct_id='$COOKIE->{ACCT}' order by id");
$Revs->execute;
$Rev = $Revs->fetchall_arrayref({});
$Revs->finish;

if ($ENV{QUERY_STRING} > 0) {
	$Layouts = $dbh->prepare("select * from invoice_layouts where acct_id='$COOKIE->{ACCT}' and id=$ENV{QUERY_STRING}");
	$Layouts->execute;
	$Layout = $Layouts->fetchrow_hashref;
	$Layouts->finish;

	$LIs = $dbh->prepare("select * from invoice_layout_items where acct_id='$COOKIE->{ACCT}' and link_id=$ENV{QUERY_STRING} order by lifldcode");
	$LIs->execute;
	$LI = $LIs->fetchall_arrayref({});
	$LIs->finish;
}
else {
	$Layout->{id} = 0;
	$Layout->{laydateformat} = '%d-%b-%y';
	@$Li = (
  { lifldcode => 'a001', lidispname => 'Invoice Type', litable => 'invoices', lisource => 'invtype', lialias => 'invtype', litop => '0', lileft => '0', lisize => '12', libold => 'N', lidisplay => 'N', lijust => 'l' },
  { lifldcode => 'a002', lidispname => 'My Address', litable => 'companies', lisource => 'concat(comname,"\\\\n",comaddress,"  ",compostcode)', lialias => 'myaddress', litop => '0', lileft => '0', lisize => '12', libold => 'N', lidisplay => 'N', lijust => 'l' },
  { lifldcode => 'a003', lidispname => 'My Phone No', litable => 'companies', lisource => 'comtel', lialias => 'mytel', litop => '0', lileft => '0', lisize => '12', libold => 'N', lidisplay => 'N', lijust => 'l' },
  { lifldcode => 'a004', lidispname => 'My Email Addr', litable => 'companies', lisource => 'comemail', lialias => 'myemail', litop => '0', lileft => '0', lisize => '12', libold => 'N', lidisplay => 'N', lijust => 'l' },
  { lifldcode => 'a005', lidispname => 'Customer Addr', litable => 'invoices', lisource => 'concat(invcusname,"\\\\n",invcusaddr,"  ",invcuspostcode)', lialias => 'cusaddress', litop => '0', lileft => '0', lisize => '12', libold => 'N', lidisplay => 'N', lijust => 'l' },
  { lifldcode => 'a006', lidispname => 'Customer FAO', litable => 'invoices', lisource => 'invcuscontact', lialias => 'cusfao', litop => '0', lileft => '0', lisize => '12', libold => 'N', lidisplay => 'N', lijust => 'l' },
  { lifldcode => 'a007', lidispname => 'Invoice #', litable => 'invoices', lisource => 'invinvoiceno', lialias => 'invoiceno', litop => '0', lileft => '0', lisize => '12', libold => 'N', lidisplay => 'N', lijust => 'l' },
  { lifldcode => 'a008', lidispname => 'Invoice Date', litable => 'invoices', lisource => 'date_format(invprintdate,"%d-%b-%y")', lialias => 'printdate', litop => '0', lileft => '0', lisize => '12', libold => 'N', lidisplay => 'N', lijust => 'l' },
  { lifldcode => 'a009', lidispname => 'Due Date', litable => 'invoices', lisource => 'date_format(invduedate,"%d-%b-%y")', lialias => 'duedate', litop => '0', lileft => '0', lisize => '12', libold => 'N', lidisplay => 'N', lijust => 'l' },
  { lifldcode => 'a010', lidispname => 'Terms', litable => 'invoices', lisource => 'invcusterms', lialias => 'custerms', litop => '0', lileft => '0', lisize => '12', libold => 'N', lidisplay => 'N', lijust => 'l' },
  { lifldcode => 'a011', lidispname => 'Customer Ref', litable => 'invoices', lisource => 'invcusref', lialias => 'cusref', litop => '0', lileft => '0', lisize => '12', libold => 'N', lidisplay => 'N', lijust => 'l' },
  { lifldcode => 'a012', lidispname => 'VAT Reg', litable => 'companies', lisource => 'comvatno', lialias => 'vatno', litop => '0', lileft => '0', lisize => '12', libold => 'N', lidisplay => 'N', lijust => 'l' },
  { lifldcode => 'a013', lidispname => 'Remarks', litable => 'invoices', lisource => 'invremarks', lialias => 'remarks', litop => '0', lileft => '0', lisize => '12', libold => 'N', lidisplay => 'N', lijust => 'l' },
  { lifldcode => 'a014', lidispname => 'Net Total', litable => 'calc', lisource => 'calc', lialias => 'nettotal', litop => '0', lileft => '0', lisize => '12', libold => 'N', lidisplay => 'N', lijust => 'r' },
  { lifldcode => 'a015', lidispname => 'VAT Total', litable => 'calc', lisource => 'calc', lialias => 'vattotal', litop => '0', lileft => '0', lisize => '12', libold => 'N', lidisplay => 'N', lijust => 'r' },
  { lifldcode => 'a016', lidispname => 'Invoice Total', litable => 'calc', lisource => 'calc', lialias => 'invtotal', litop => '0', lileft => '0', lisize => '12', libold => 'N', lidisplay => 'N', lijust => 'r' },
  { lifldcode => 'a017', lidispname => 'Company Reg', litable => 'companies', lisource => 'comregno', lialias => 'regno', litop => '0', lileft => '0', lisize => '12', libold => 'N', lidisplay => 'N', lijust => 'l' },
  { lifldcode => 'a018', lidispname => 'Bank Sort Code', litable => 'accounts', lisource => 'accsort', lialias => 'sortcode', litop => '0', lileft => '0', lisize => '12', libold => 'N', lidisplay => 'N', lijust => 'l' },
  { lifldcode => 'a019', lidispname => 'Bank Acct #', litable => 'accounts', lisource => 'accacctno', lialias => 'acctno', litop => '0', lileft => '0', lisize => '12', libold => 'N', lidisplay => 'N', lijust => 'l' },
  { lifldcode => 'a020', lidispname => 'Item Description', litable => 'items', lisource => '0', lialias => 'desc', litop => '0', lileft => '0', lisize => '10', libold => 'N', lidisplay => 'N', lijust => 'l' },
  { lifldcode => 'a021', lidispname => 'Item Quantity', litable => 'items', lisource => '2', lialias => 'qty', litop => '0', lileft => '0', lisize => '10', libold => 'N', lidisplay => 'N', lijust => 'l' },
  { lifldcode => 'a022', lidispname => 'Item Unit Price', litable => 'items', lisource => '1', lialias => 'price', litop => '0', lileft => '0', lisize => '10', libold => 'N', lidisplay => 'N', lijust => 'r' },
  { lifldcode => 'a023', lidispname => 'Item Net Total', litable => 'items', lisource => '3', lialias => 'net', litop => '0', lileft => '0', lisize => '10', libold => 'N', lidisplay => 'N', lijust => 'r' },
  { lifldcode => 'a024', lidispname => 'Item VAT Rate', litable => 'items', lisource => '4', lialias => 'vrate', litop => '0', lileft => '0', lisize => '10', libold => 'N', lidisplay => 'N', lijust => 'l' },
  { lifldcode => 'a025', lidispname => 'Item VAT Total', litable => 'items', lisource => '5', lialias => 'vat', litop => '0', lileft => '0', lisize => '10', libold => 'N', lidisplay => 'N', lijust => 'r' },
  { lifldcode => 'a026', lidispname => 'Item Total', litable => 'items', lisource => '6', lialias => 'itmtotal', litop => '0', lileft => '0', lisize => '10', libold => 'N', lidisplay => 'N', lijust => 'r' },
  { lifldcode => 'a027', lidispname => 'Delivery Address', litable => 'customers', lisource => 'cusdeliveryaddr', lialias => 'delivaddr', litop => '0', lileft => '0', lisize => '12', libold => 'N', lidisplay => 'N', lijust => 'l' },
);

}

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
        WRAPPER => 'header.tt',
});

$Vars = {
        title => 'Accounts - Invoice Layouts',
	cookie => $COOKIE,
	focus => 'laydesc',
	layout => $Layout,
	revs => $Rev,
	lis => $LI,
        javascript => '<script type="text/javascript"> 
var errfocus = "";
var uploadparms = "";
$(document).ready(function(){
  $("#layfile").uploadify({
    "uploader"    : "/js/uploadify.swf",
    "script"      : "/cgi-bin/fpa/add_invoice_layout2.pl",
    "cancelImg"   : "/js/cancel.png",
    "scriptData"  : {"cookie" : "'.$COOKIE->{COOKIE}.'", "doc_type" : "LAYOUT" },
    "buttonText"  : "Select Layout",
    "fileExt"     : "*.pdf;*.jpg;*.png",
    "fileDesc"    : "Invoice Layout Files (PDF,JPG,PNG)",
    "sizeLimit"   : 102400,
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
function check_send() {
  if ($("#layid").val() == 0 && ($("#laydesc").val() == "" || $("#layfileQueue").html() == "")) {
    alert("You must enter a description iand select a layout file when adding a new layout");
  }
  else {
    if ($("#layfileQueue").html() == "") {
        $.post("/cgi-bin/fpa/add_invoice_layout2.pl", "cookie='.$COOKIE->{COOKIE}.'&doc_type=LAYOUT&"+$("#layform").serialize(),function(data) {
          if (/Error/i.test(data)) {
            alert(data);
          }
          else {
            location.href="/cgi-bin/fpa/layout_invoice_layout.pl?" + data;
          }
        },"text");

    }
    else {
      $("#layfile").uploadifySettings( "scriptData",{ "uploadparms" : $("#layform").serialize() });
      $("#layfile").uploadifyUpload();
    }
  }
}
function setfocus() {
  eval("document.getElementById(\'" + errfocus + "\').focus();");
}
</script>',
};

print "Content-Type: text/html\n\n";
$tt->process('add_invoice_layout.tt',$Vars);

$dbh->disconnect;
exit;

