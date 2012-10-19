#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to display Nominal Ledger (ie all nominals)

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");

#  First get the initial date range

($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});
$Regs = $dbh->prepare("select date_format(date_sub(regregdate,interval 6 month),'%d-%b-%y') as tbstart,date_format(now(),'%d-%b-%y') as tbend,date_add(date_sub(comyearend,interval 1 year),interval 1 day) as tbfy from registrations left join companies on (registrations.reg_id=companies.reg_id) where registrations.reg_id=$Reg_id and companies.id=$Com_id");
$Regs->execute;
$Reg = $Regs->fetchrow_hashref;
$Reg->{tbselect} = "cu";
($Yr,$Mth,$Day) = split(/-/,$Reg->{tbfy});
$Mth--;
$Startstr = $Reg->{tbstart};
$Curstr = $Reg->{tbend};

#  Get settings from tempstacks

if ($ENV{QUERY_STRING} =~ /F/i) {
        $Sts = $dbh->do("update tempstacks set f1='',f2='',f3='' where acct_id='$COOKIE->{ACCT}' and caller='report'");
        $Reg->{tbselect} = "ly";

}
else {

        $TSs = $dbh->prepare("select f1,f2,f3 from tempstacks where acct_id='$COOKIE->{ACCT}' and caller='report'");
        $TSs->execute;
        $TS = $TSs->fetchrow_hashref;

        if ($TS->{f1}) {
                $Reg->{tbselect} = $TS->{f1};
                $Reg->{tbstart} = $TS->{f2};
                $Reg->{tbend} = $TS->{f3};
        }
        $TSs->finish;
}

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
        WRAPPER => 'header.tt',
});

$Vars = {
	 ads => $Adverts,
        title => 'Aged Debtors',
	cookie => $COOKIE,
	daterange => $Reg,
	javascript => '<script type="text/javascript">
$(document).ready(function(){
  $("#tbstart").datepicker({minDate: new Date(2000,01 - 1,01) });
  $("#tbend").datepicker();
  $("#tbselect").val("'.$Reg->{tbselect}.'");
  $("#tbselect").trigger("change");
  get_balances();
});
function display_bs() {
   location.href="/cgi-bin/fpa/balance_sheet.pl?" + $("form#form1").serialize();
}
function set_range(obj) {
  var startstr = "'.$Startstr.'";
  var curstr = "'.$Curstr.'";
  var curdate = new Date();
  var fydate = new Date();
  fydate.setFullYear('.$Yr.','.$Mth.','.$Day.');

  switch(obj.value) {
    case "cu":
      document.getElementById("tbstart").value = startstr;
      document.getElementById("tbend").value = curstr;
      break;

    case "tw":
      curdate.setDate(curdate.getDate() - curdate.getDay() + 1);
      var curarray = curdate.toUTCString().split(" ");
      document.getElementById("tbstart").value = curarray[1] + "-" + curarray[2] + "-" + curarray[3].substring(2);
      document.getElementById("tbend").value = curstr;
      break;

    case "tm":
      curdate.setDate(1);
      var curarray = curdate.toUTCString().split(" ");
      document.getElementById("tbstart").value = curarray[1] + "-" + curarray[2] + "-" + curarray[3].substring(2);
      document.getElementById("tbend").value = curstr;
      break;

    case "tq":
      var thismonth = curdate.getMonth();
      var fqstart = fydate.getMonth();
      for (var i=0;i<11;i=i+3) {
        if (thismonth >= fqstart && thismonth < fqstart + 3) {
          break;
        }
        else {
          fqstart = fqstart + 3;
          if (fqstart > 11) {
            fqstart = fqstart - 12;
          }
        }
      }
      curdate.setMonth(curdate.getMonth() - thismonth + fqstart,1);
      var curarray = curdate.toUTCString().split(" ");
      document.getElementById("tbstart").value = curarray[1] + "-" + curarray[2] + "-" + curarray[3].substring(2);
      document.getElementById("tbend").value = curstr;
      break;

    case "ty":
      var fyarray = fydate.toUTCString().split(" ");
      document.getElementById("tbstart").value = fyarray[1] + "-" + fyarray[2] + "-" + fyarray[3].substring(2);
      document.getElementById("tbend").value = curstr;
      break;

    case "lw":
      curdate.setDate(curdate.getDate() - curdate.getDay());
      var curarray = curdate.toUTCString().split(" ");
      document.getElementById("tbend").value = curarray[1] + "-" + curarray[2] + "-" + curarray[3].substring(2);
      curdate.setDate(curdate.getDate() - 7);
      curarray = curdate.toUTCString().split(" ");
      document.getElementById("tbstart").value = curarray[1] + "-" + curarray[2] + "-" + curarray[3].substring(2);
      break;

    case "lm":
      curdate.setDate(0);
      var curarray = curdate.toUTCString().split(" ");
      document.getElementById("tbend").value = curarray[1] + "-" + curarray[2] + "-" + curarray[3].substring(2);
      curdate.setDate(1);
      curarray = curdate.toUTCString().split(" ");
      document.getElementById("tbstart").value = curarray[1] + "-" + curarray[2] + "-" + curarray[3].substring(2);
      break;

    case "lq":
      var thismonth = curdate.getMonth();
      var fqstart = fydate.getMonth();
      for (var i=0;i<11;i=i+3) {
        if (thismonth >= fqstart && thismonth < fqstart + 3) {
          break;
        }
        else {
          fqstart = fqstart + 3;
          if (fqstart > 11) {
            fqstart = fqstart - 12;
          }
        }
      }
      curdate.setMonth(curdate.getMonth() - thismonth + fqstart,1);
      var curarray = curdate.toUTCString().split(" ");
      document.getElementById("tbend").value = curarray[1] + "-" + curarray[2] + "-" + curarray[3].substring(2);
      curdate.setMonth(curdate.getMonth() - 2,1);
      curarray = curdate.toUTCString().split(" ");
      document.getElementById("tbstart").value = curarray[1] + "-" + curarray[2] + "-" + curarray[3].substring(2);
      break;

    case "ly":
      fydate.setDate(fydate.getDate() - 1);
      var fyarray = fydate.toUTCString().split(" ");
      document.getElementById("tbend").value = fyarray[1] + "-" + fyarray[2] + "-" + fyarray[3].substring(2);
      fydate.setMonth(fydate.getMonth() - 11,1);
      var fyarray = fydate.toUTCString().split(" ");
      document.getElementById("tbstart").value = fyarray[1] + "-" + fyarray[2] + "-" + fyarray[3].substring(2);
      break;

    default:
      document.getElementById("tbstart").value = startstr;
      document.getElementById("tbend").value = curstr;
      break;

  }
  get_balances();
}
function get_balances() {
   $.get("/cgi-bin/fpa/aged_debtors_results.pl",$("form#form1").serialize() ,function(data) {
     $("#results").html(data);
  });
}
function print_list() {
   $.get("/cgi-bin/fpa/print_aged_debtors_results.pl",$("form#form1").serialize() ,function(data) {
     $("#main").html(data);
     $("#htmltabs").hide();
     $("#printtab").show();
   });
}
</script>'
};

print "Content-Type: text/html\n\n";
$tt->process('aged_debtors.tt',$Vars);

$Regs->finish;
$dbh->disconnect;
exit;

