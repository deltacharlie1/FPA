#!/usr/bin/perl

$ACCESS_LEVEL = 4;

#  script to re-assign Nominal codes after creating additonal nominal accoounts

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");
($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});

#  Get the start of this FY

$Companies = $dbh->prepare("select date_add(date_sub(comyearend,interval 2 year), interval 1 day) as fystart from companies where reg_id=$Reg_id and id=$Com_id");
$Companies->execute;
$Company = $Companies->fetchrow_hashref;
$Companies->finish;

$Coas = $dbh->prepare("select nominals.id as nomid,nominals.nomcode,nominals.nomtype,nominals.link_id,coadesc,coatype,nominals.nomamount as balance,date_format(nominals.nomdate,'%d-%b-%y') as printdate,concat(txncusname,' (',txnremarks,')') as txndescr,concat(invcusname,' (',invdesc,')') as invdescr from nominals left join coas on (nominals.nomcode=coas.coanominalcode and nominals.acct_id=coas.acct_id) left join transactions on (nominals.link_id=transactions.id and nominals.acct_id=transactions.acct_id) left join invoices on (nominals.link_id=invoices.id and nominals.acct_id=invoices.acct_id) where '$Company->{fystart}'<=nominals.nomdate and (nominals.nomcode like '4%' or (nominals.nomcode>='5000' and nominals.nomcode<'6500') or (nominals.nomcode>='7000' and nominals.nomcode<'7500'))  and nominals.acct_id='$COOKIE->{ACCT}' order by nominals.nomcode,nominals.nomdate");
$Coas->execute;
$Coa = $Coas->fetchall_arrayref({});
$Coas->finish;

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
        WRAPPER => 'header.tt',
});

$Vars = {
	 ads => $Adverts,
        title => 'Re-assign Nominal Codes',
	cookie => $COOKIE,
	coas => $Coa,
	javascript => '<script type="text/javascript">
function checkcode(id) {
  var errs = "";
  var oldcode = $("#nom"+id).parent().parent().find(":first-child").text();
  var newcode = $("#nom"+id).val();
 
  if (!/^\d\d\d\d$/.test(newcode)) {
    errs = errs + " - New Code must be numeric\\n";
  }
  if (/^43/.test(oldcode) && !/^43/.test(newcode)) {
    errs = errs + " - New Code must be in the range 4310-4399\\n";
  }
  else {
    var oldsub = oldcode.substring(0,1);
    var newsub = newcode.substring(0,1);

    if (newsub < 4) {
      errs = errs + " - New Code must be 4000 or higher (a P & L item)\\n";
    }
    else {
      if (oldsub > 4 && newsub < 5) {
        errs = errs + " - New Code must be an Expenses Code\\n";
      }
      else {
        if (oldsub < 5 && newsub > 4) {
          errs = errs + " - New Code must be an Income code\\n";
        }
      }
    }
  }

  if (errs.length > 0) {
    alert ("You have the following errors:-\\n\\n" + errs);
    document.getElementById("nom"+id).value = "";
    document.getElementById("nom"+id).focus();
  }
}
</script>'
};

print "Content-Type: text/html\n\n";
$tt->process('reassign_nominals.tt',$Vars);
$dbh->disconnect;
exit;

