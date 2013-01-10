#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to display Nominal Ledger (ie all nominals)

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");

#  First get the initial date range

($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});
$Regs = $dbh->prepare("select date_format(date_sub(regregdate,interval 6 month),'%d-%b-%y') as tbstart,date_format(now(),'%d-%b-%y') as tbend,date_add(date_sub(comyearend,interval 1 year),interval 1 day) as tbfy,dayofweek(curdate()) as dow from registrations left join companies on (registrations.reg_id=companies.reg_id) where registrations.reg_id=$Reg_id and companies.id=$Com_id");
$Regs->execute;
$Reg = $Regs->fetchrow_hashref;
$Reg->{tbselect} = "ly";
($Yr,$Mth,$Day) = split(/-/,$Reg->{tbfy});
$Mth--;
$DOW = $Reg->{dow} - 2;
if ($DOW < 0) { $DOW = 6; }

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
        title => 'Transactions Report',
	cookie => $COOKIE,
	daterange => $Reg,
	javascript => '<script type="text/javascript">
$(document).ready(function(){
  $("#changedescr").dialog({
    bgiframe: true,
    autoOpen: false,
    position: [100,100],
    height: 200,
    width: 500,
    modal: true,
    buttons: {
      "Change Description": function() {
        $.post("/cgi-bin/fpa/change_invoice_descr.pl", $("#fchangedescr").serialize(),function(data) {
          if ( ! /^OK/.test(data)) {
            alert(data);
          }
          window.location.reload(true);
        },"text");
        $("td").removeClass("error");
        $(this).dialog("close");
      },
      Cancel: function() {
        $("td").removeClass("error");
        $(this).dialog("close");
      }
    }
  });

  $("#tbstart").datepicker({minDate: new Date(2000,01 - 1,01) });
  $("#tbend").datepicker();
  $("#tbselect").val("'.$Reg->{tbselect}.'");
  $("#tbselect").trigger("change");
  get_balances();
});
function set_range(obj) {
  var monthnames = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"];
  var startstr = "'.$Reg->{tbstart}.'";
  var curstr = "'.$Reg->{tbend}.'";
  var curdate = new Date();
  var fydate = new Date();
  fydate.setFullYear('.$Yr.','.$Mth.','.$Day.');
  switch(obj.value) {
    case "cu":
      document.getElementById("tbstart").value = "'.$Reg->{tbstart}.'";
      document.getElementById("tbend").value = "'.$Reg->{tbend}.'";
      break;

    case "tw":
      curdate.setDate(curdate.getDate() - '.$DOW.');
      var thisday = ("0" + curdate.getDate().toString()).slice(-2);
      document.getElementById("tbstart").value = thisday + "-" + monthnames[curdate.getMonth().toString()] + "-" + curdate.getFullYear().toString().substring(2);
      document.getElementById("tbend").value = curstr;
      break;

    case "tm":
      document.getElementById("tbstart").value = "01-" + monthnames[curdate.getMonth().toString()] + "-" + curdate.getFullYear().toString().substring(2);
      document.getElementById("tbend").value = curstr;
      break;

    case "tq":
      for (var i=0;i<11;i=i+3) {
        if (fydate.valueOf() > curdate.valueOf()) {
          fydate.setMonth(fydate.getMonth() - 3);
          break;
        }
        else {
          fydate.setMonth(fydate.getMonth() + 3);
        }
      }
      document.getElementById("tbstart").value = "01-" + monthnames[fydate.getMonth().toString()] + "-" + fydate.getFullYear().toString().substring(2);
      document.getElementById("tbend").value = curstr;
      break;

    case "ty":
      document.getElementById("tbstart").value = "'.$Day.'" + "-" + monthnames['.$Mth.'] + "-" + "'.substr($Yr,2).'";
      document.getElementById("tbend").value = curstr;
      break;

    case "lw":
      curdate.setDate(curdate.getDate() - 7);
      curdate.setDate(curdate.getDate() - '.$DOW.');
      document.getElementById("tbstart").value = ("0" + curdate.getDate().toString()).slice(-2) + "-" + monthnames[curdate.getMonth().toString()] + "-" + curdate.getFullYear().toString().substring(2);
      curdate.setDate(curdate.getDate() + 6);
      document.getElementById("tbend").value = ("0" + curdate.getDate().toString()).slice(-2) + "-" + monthnames[curdate.getMonth().toString()] + "-" + curdate.getFullYear().toString().substring(2);
      break;

    case "lm":
      curdate.setMonth(curdate.getMonth() - 1);
      document.getElementById("tbstart").value = "01-" + monthnames[curdate.getMonth().toString()] + "-" + curdate.getFullYear().toString().substring(2);
      curdate.setMonth(curdate.getMonth() + 1);
      curdate.setDate(- '.$Day.' + 1);
      document.getElementById("tbend").value = curdate.getDate().toString() + "-" + monthnames[curdate.getMonth().toString()] + "-" + curdate.getFullYear().toString().substring(2);
      break;

    case "lq":
      for (var i=0;i<11;i=i+3) {
        if (fydate.valueOf() > curdate.valueOf()) {
          fydate.setMonth(fydate.getMonth() - 3);
          break;
        }
        else {
          fydate.setMonth(fydate.getMonth() + 3);
        }
      }
      fydate.setMonth(fydate.getMonth() - 3);
      document.getElementById("tbstart").value = ("0" + fydate.getDate()).slice(-2) + "-" + monthnames[fydate.getMonth().toString()] + "-" + fydate.getFullYear().toString().substring(2);
      fydate.setMonth(fydate.getMonth() + 3);
      fydate.setDate(fydate.getDate() - 1);
      document.getElementById("tbend").value = ("0" + fydate.getDate()).slice(-2) + "-" + monthnames[fydate.getMonth().toString()] + "-" + fydate.getFullYear().toString().substring(2);
      break;

    case "ly":
      var lystart = new Date();
      lystart.setFullYear('.$Yr.','.$Mth.','.$Day.');
      lystart.setFullYear(lystart.getFullYear() - 1);
      document.getElementById("tbstart").value = ("0" + lystart.getDate()).slice(-2) + "-" + monthnames[lystart.getMonth().toString()] + "-" + lystart.getFullYear().toString().substring(2);
      fydate.setDate(fydate.getDate() - 1);
      document.getElementById("tbend").value = ("0" + fydate.getDate()).slice(-2) + "-" + monthnames[fydate.getMonth().toString()] + "-" + fydate.getFullYear().toString().substring(2);
      break;

    default:
      document.getElementById("tbstart").value = startstr;
      document.getElementById("tbend").value = curstr;
      break;

  }
  get_balances();
}
function get_balances() {
   $.get("/cgi-bin/fpa/nom_txns_results.pl",$("form#form1").serialize() ,function(data) {
     $("#results").html(data);
  });
}
function print_list() {
   $.get("/cgi-bin/fpa/print_nom_txns_results.pl",$("form#form1").serialize() ,function(data) {
     $("#main").html(data);
     $("#htmltabs").hide();
     $("#printtab").show();
   });
}
function change_descr(obj,id,olddescr) {
  $(obj).addClass("error");
  document.getElementById("cd_id").value = id;
  document.getElementById("newdescr").value = olddescr;
  $("#changedescr").dialog("open");
}
</script>'
};

print "Content-Type: text/html\n\n";
$tt->process('nom_txns.tt',$Vars);

$Regs->finish;
$dbh->disconnect;
exit;


