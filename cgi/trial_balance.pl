#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to display Chart of Account details

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

use DBI;
my $dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");

#  First get the initial date range

($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});
$Regs = $dbh->prepare("select date_format(date_sub(regregdate,interval 6 month),'%d-%b-%y') as tbstart,date_format(now(),'%d-%b-%y') as tbend,date_add(date_sub(comyearend,interval 1 year),interval 1 day) as tbfy from registrations left join companies on (registrations.reg_id=companies.reg_id) where registrations.reg_id=$Reg_id and companies.id=$Com_id");
$Regs->execute;
$Reg = $Regs->fetchrow_hashref;
($Yr,$Mth,$Day) = split(/-/,$Reg->{tbfy});
$Mth--;

$Coas = $dbh->prepare("select nomcode,coadesc,coatype,sum(nomamount) as balance from nominals left join coas on (nominals.nomcode=coas.coanominalcode and nominals.acct_id=coas.acct_id) where nominals.acct_id='$COOKIE->{ACCT}' group by nomcode having balance<>0 order by nomcode");
$Coas->execute;

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
        WRAPPER => 'header.tt',
});

$Vars = {
        title => 'Accounts - Trial Balance',
	cookie => $COOKIE,
	entries => $Coas->fetchall_arrayref({}),
	daterange => $Reg,
	javascript => '<script type="text/javascript">
$(document).ready(function(){
  $("#tbstart").datepicker({minDate: new Date(2000,01 - 1,01) });
  $("#tbend").datepicker();
  get_balances();
});
function set_range(obj) {
  var startstr = "'.$Reg->{tbstart}.'";
  var curstr = "'.$Reg->{tbend}.'";
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
      var curarray = curdate.toDateString().split(" ");
      document.getElementById("tbstart").value = curarray[2] + "-" + curarray[1] + "-" + curarray[3].substring(2);
      document.getElementById("tbend").value = curstr;
      break;

    case "tm":
      curdate.setDate(1);
      var curarray = curdate.toDateString().split(" ");
      document.getElementById("tbstart").value = curarray[2] + "-" + curarray[1] + "-" + curarray[3].substring(2);
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
      curdate.setMonth(curdate.getMonth() - thismonth + fqstart);
      curdate.setDate(1);
      var curarray = curdate.toDateString().split(" ");
      document.getElementById("tbstart").value = curarray[2] + "-" + curarray[1] + "-" + curarray[3].substring(2);
      document.getElementById("tbend").value = curstr;
      break;

    case "ty":
      var fyarray = fydate.toDateString().split(" ");
      document.getElementById("tbstart").value = fyarray[2] + "-" + fyarray[1] + "-" + fyarray[3].substring(2);
      document.getElementById("tbend").value = curstr;
      break;

    case "lw":
      curdate.setDate(curdate.getDate() - curdate.getDay());
      var curarray = curdate.toDateString().split(" ");
      document.getElementById("tbend").value = curarray[2] + "-" + curarray[1] + "-" + curarray[3].substring(2);
      curdate.setDate(curdate.getDate() - 7);
      curarray = curdate.toDateString().split(" ");
      document.getElementById("tbstart").value = curarray[2] + "-" + curarray[1] + "-" + curarray[3].substring(2);
      break;

    case "lm":
      curdate.setDate(0);
      var curarray = curdate.toDateString().split(" ");
      document.getElementById("tbend").value = curarray[2] + "-" + curarray[1] + "-" + curarray[3].substring(2);
      curdate.setDate(1);
      curarray = curdate.toDateString().split(" ");
      document.getElementById("tbstart").value = curarray[2] + "-" + curarray[1] + "-" + curarray[3].substring(2);
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
      curdate.setMonth(curdate.getMonth() - thismonth + fqstart);
      curdate.setDate(0);
      var curarray = curdate.toDateString().split(" ");
      document.getElementById("tbend").value = curarray[2] + "-" + curarray[1] + "-" + curarray[3].substring(2);
      curdate.setMonth(curdate.getMonth() - 2);
      curdate.setDate(1);
      curarray = curdate.toDateString().split(" ");
      document.getElementById("tbstart").value = curarray[2] + "-" + curarray[1] + "-" + curarray[3].substring(2);
      break;

    case "ly":
      fydate.setDate(fydate.getDate() - 1);
      var fyarray = fydate.toDateString().split(" ");
      document.getElementById("tbend").value = fyarray[2] + "-" + fyarray[1] + "-" + fyarray[3].substring(2);
      fydate.setMonth(fydate.getMonth() - 11);
      fydate.setDate(1);
      var fyarray = fydate.toDateString().split(" ");
      document.getElementById("tbstart").value = fyarray[2] + "-" + fyarray[1] + "-" + fyarray[3].substring(2);
      break;

    default:
      document.getElementById("tbstart").value = startstr;
      document.getElementById("tbend").value = curstr;
      break;

  }
  get_balances();
}
function get_balances() {
   $.get("/cgi-bin/fpa/trial_balance_results.pl",$("form#form1").serialize() ,function(data) {
     document.getElementById("results").innerHTML = data;
  });
}

</script>'
};

print "Content-Type: text/html\n\n";
$tt->process('trial_balance.tt',$Vars);

$Coas->finish;
$Regs->finish;
$dbh->disconnect;
exit;

