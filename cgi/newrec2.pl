#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to reconcile an account

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

use CGI;
use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");
$Data = new CGI;
%FORM = $Data->Vars;

while (( $Key,$Value) = each %FORM) {

#  Remove any bad characters

	$Value =~ tr/\\//d;
#	$Value =~ s/\'/\\\'/g;
        $FORM{$Key} = $Value;
}

#  Check to see if we have an exisitng spreadsheet saved

$FORM{stmt} =~ s/\\\'/\'/g;	#  strip out any exisitng escapes
$FORM{stmt} =~ s/\'/\\\'/g;	#  then add thm back so we don't miss any

if ($FORM{acctype}) {
	$Sts = $dbh->do("update tempstacks set f1='$FORM{stmt}',f2='$FORM{stmtno}',f4='$FORM{acctype}' where acct_id='$COOKIE->{ACCT}' and caller='reconciliation'");
}
else {
	$TSs = $dbh->prepare("select f1,f2,f4 from tempstacks where acct_id='$COOKIE->{ACCT}' and caller='reconciliation'");
	$TSs->execute;
	($FORM{stmt},$FORM{stmtno},$FORM{acctype}) = $TSs->fetchrow;
	$TSs->finish;
}

#  First get all unreconciled TRansactions

$Txns = $dbh->prepare("select id,txntxntype,date_format(txndate,'%d-%b-%y') as tdate,link_id,txncusname,txnremarks,txnamount from transactions where txnselected<>'F' and txnmethod='$FORM{acctype}' and acct_id='$COOKIE->{ACCT}' order by txndate");
$Txns->execute;
$Txn = $Txns->fetchall_arrayref({});
$Txns->finish;

#  Then get all unpaid invoices

$Invoices = $dbh->prepare("select id,invtype,date_format(invprintdate,'%d-%b-%y') as printdate,cus_id,invinvoiceno,invcusname,invdesc,(invtotal+invvat-invpaid-invpaidvat) as amtdue,invprintdate from invoices where acct_id='$COOKIE->{ACCT}' and invstatuscode>2 union select vatreturns.id,if(perbox5<0,'vatr','vatp') as invtype,date_format(perstatusdate,'%d-%b-%y') as printdate,0,'vat','HMRC',concat('Quarter End ',perquarter) as invdesc,0-perbox5 as amtdue,perstatusdate as invprintdate from vatreturns where acct_id='$COOKIE->{ACCT}' and perstatus='Filed' order by invprintdate");
$Invoices->execute;
$Invoice = $Invoices->fetchall_arrayref({});
$Invoices->finish;

$FORM{stmt} =~ s/\\\'/\'/g;	#  and strip them out again

$Accts = $dbh->prepare("select accounts.id,accounts.acctype,accname,accacctno,stastmtno,staclosebal,date_format(staclosedate,'%d-%b-%y') as staclosedate from accounts left join statements on (accounts.id=acc_id) where accounts.acct_id='$COOKIE->{ACCT}' and acctype='$FORM{acctype}' order by statements.id desc limit 1");
$Accts->execute;
$Acct = $Accts->fetchrow_hashref;
$Accts->finish;

if ($FORM{source} =~ /HSBC/i) {
	$Date_posn = "0";
	$Desc_posn = "2";
	$Outamt_posn = "3";
	$Inamt_posn = "4";
	$Bal_posn = "5";
}
elsif ($FORM{source} =~ /Lloyds/i) {
	$Date_posn = "0";
	$Desc_posn = "4";
	$Outamt_posn = "5";
	$Inamt_posn = "6";
	$Bal_posn = "7";
}
elsif ($FORM{source} =~ /NatWest/i) {
	$Date_posn = "0";
	$Desc_posn = "2";
	$Outamt_posn = "8";
	$Inamt_posn = "3";
	$Bal_posn = "4";
}
elsif ($FORM{source} =~ /Santander/i) {
	$Date_posn = "1";
	$Desc_posn = "3";
	$Outamt_posn = "6";
	$Inamt_posn = "5";
	$Bal_posn = "7";
}
else {
	$Date_posn = "0";
	$Desc_posn = "2";
	$Outamt_posn = "3";
	$Inamt_posn = "4";
	$Bal_posn = "5";
}

@Month = ('','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec');
%hMonth = ('Jan','01','Feb','02','Mar','03','Apr','04','May','05','Jun','06','Jul','07','Aug','08','Sep','09','Oct','10','Nov','11','Dec','12');

$Total = 0;
warn "\n\n";

$FORM{stmt} =~ tr/\r//d;
@Rows = split(/\n/,$FORM{stmt});
foreach $Row (@Rows) {
	chomp($Row);
	@Cell = split(/\t/,$Row);
	next unless ($Cell[$Date_posn] =~ /^(\d+\/\d+\/\d+|\d+.\w\w\w.\d+$)/i);

#  Strip out any non curency characters

	$Cell[$Outamt_posn] =~ tr/[0-9]\-\.//cd;
	$Cell[$Inamt_posn] =~ tr/[0-9]\-\.//cd;
	$Cell[$Bal_posn] =~ tr/[0-9]\-\.//cd;
	$Cell[$Desc_posn] =~ s/^\'//;		#  strip out any excel text marker

	if ($Cell[$Date_posn]) {
		if ($Cell[$Outamt_posn] =~ /^\d/) {
			$Cell[$Inamt_posn] = 0-$Cell[$Outamt_posn];
		}

		$Entry = {};
		($Day,$Mth,$Yr) = $Cell[$Date_posn] =~ /(\d+)?[-\/ ](\w+)[-\/ ]2?0?(\d+)/;
		$Month = $Month[$Mth] || $Mth;
		$Entry->{date} = "$Day-$Month-$Yr";
		$Entry->{desc} = $Cell[$Desc_posn];
		$Entry->{amt} = $Cell[$Inamt_posn];
		$Entry->{balance} = $Cell[$Bal_posn];
#		warn "\$Entry->{sortkey} = $Yr.$hMonth{$Month}.$Day\n";
		$Entry->{sortkey} = $Yr.$hMonth{$Month}.$Day;

		push(@uStmt,$Entry);

		$Total += abs($Cell[$Inamt_posn]);
	}
}

@Stmt = sort { $a->{sortkey} <=> $b->{sortkey} } @uStmt;

#  Calculate the opening balance

$Safety_count = 0;
while (@Stmt[$Safety_count]->{balance} !~ /\d+/ && $Safety_count < 1000) {
	$Acct->{newopen} -= @Stmt[$Safety_count]->{amt};
	$Safety_count++;
}

$Acct->{newopen} += @Stmt[$Safety_count]->{balance} - @Stmt[$Safety_count]->{amt};
$Acct->{newclose} = @Stmt[$#Stmt]->{balance} || 0;

$TSs = $dbh->prepare("select f1,f2,f3 from tempstacks where acct_id='$COOKIE->{ACCT}' and caller='reconciliation'");
$TSs->execute;
$TS = $TSs->fetchrow_hashref;
$TSs->finish;

#  Get te laast statement close date to make sure that these entries are for a new statement

$Stmts = $dbh->prepare("select datediff(str_to_date('@Stmt[0]->{date}','%d-%b-%y'),staclosedate) as stmtdiff from statements left join accounts on (acc_id=accounts.id and statements.acct_id=accounts.acct_id) where statements.acct_id='$COOKIE->{ACCT}' and accounts.acctype='$FORM{acctype}' order by staclosedate desc limit 1");
$Stmts->execute;
$Last_Stmt = $Stmts->fetchrow_hashref;
$Stmts->finish;

if ($COOKIE->{ACCT} == '1+1') {
	$GCcalc = '$("#stmtdiff").text($("#stmtdiff").text() - $("#gctot").val());';
}
use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
        WRAPPER => 'header.tt',
});

$Vars = {
	 ads => $Adverts,
        title => 'Accounts - Reconciliations',
	cookie => $COOKIE,
	acct => $Acct,
	invoices => $Invoice,
	txns => $Txn,
	stmt => \@Stmt,
	last_stmt => $Last_Stmt,
	stack => $TS,
	javascript => '<script type="text/javascript">
var errfocus;
var absvalue = '.$Total.';
$(document).ready(function(){'.$GCcalc.'
  $("#newdate").datepicker({ maxDate: new Date() });
  $("#changedate").dialog({
    bgiframe: true,
    autoOpen: false,
    position: [200,100],
    height: 200,
    width: 300,
    modal: true,
    buttons: {
      "Change Date": function() {
        $.post("/cgi-bin/fpa/change_txn_date.pl", $("#fchangedate").serialize(),function(data) {
          if ( ! /^OK/.test(data)) {
            alert(data);
          }
          window.location.href="/cgi-bin/fpa/newrec2.pl";
//          window.location.reload(true);
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
//  $("#sidebar ul").hide();
  $(".stmttxndate").datepicker();
  $("#stmt_cus_id").autocomplete({
    minLength: 0,
    delay: 50,
    source: function (request,response) {
      request.type = $("#stmtcustype").val();
      $.ajax({
        url: "/cgi-bin/fpa/autosuggest.pl",
        dataType: "json",
        data: request,
        success: function( data ) {
          response (data);
        }
      });
    },
    select: function(event, ui) {
      $("#stmtcusid").val(ui.item.id);
      $("#stmtinccodes").val(ui.item.coa);
      $("#stmtpaycodes").val(ui.item.coa);
      $("#stmtvatrate").val(ui.item.vatrate);
      $("#rec_cuscis").val(ui.item.cuscis);
      if (ui.item.cuscis == "Y") {
        $("#cistext").show();
        $("#cisamount").show();
      }
      else {
        $("#cistext").hide();
        $("#cisamount").hide();
      }
      calc_stmtvat();
    }
  });
  $("#stmtmatch").dialog({
    bgiframe: true,
    autoOpen: false,
    position: [200,50],
    height: 380,
    width: 500,
    modal: true,
    buttons: {
  "Add Transaction": function() {
     var errs = "";
     if (!(/6010/.test($("#stmtpaycodes").val()) || /4310/.test($("#stmtinccodes").val())) && $("#stmt_cus_id").val() == "") {
       errs = errs + "<li>You must enter a Customer/Supplier name</li>";
       errfocus = "stmt_cus_id";
     }
     if ($("#stmtdesc").val() == "") {
       errs = errs + "<li>You must enter a Transaction Description</li>";
     }
     if (errs != "") {
       $("#dialog").html("You have the following errors:-<ol>" + errs + "</ol>");
       $("#dialog").dialog("open");
     }
     else {
       var trid = document.getElementById("stmtdropid").value;
       $("#"+trid).find(".placeholder").remove();
       if (/^Sup/.test($("#stmtcustype").val())) {
         var purtype = "new pur";
         if ($("#stmtpaycodes").val() == "6010") {
           purtype = "chrgs";
         }
         $("<tr></tr>").html("<td style=\'display:none;\'>"+$("#stmtcusid").val()+"</td><td style=\'display:none;\'>"+purtype+"</td><td nowrap=\'nowrap\'>"+$("#stmtpaytxndate").val()+"</td><td>"+document.getElementById("stmtvatrate").value+"</td><td>"+$("#stmtpaycodes").val()+"</td><td>"+$("#stmt_cus_id").val()+"</td><td>"+$("#stmtdesc").val()+"</td><td>-"+$("#stmttxnamount").text()+"</td><td style=\'display:none;\'>-"+$("#stmtvat").text()+"</td><td style=\'display:none;\'>"+$("#stmtcusref").val()+"</td><td style=\'display:none;\'>"+$("#stmtitem_cat").val()+"</td><td onclick=\"revert(\'0\',$(this),\'"+trid+"\');\"><img src=\'/icons/delete.png\' width=\'12\' height=\'12\' alt=\'Delete\'/></td>").appendTo("#"+trid);
         var diff = document.getElementById("stmtdiff").innerHTML;
         diff = (diff * 1) + ($("#stmttxnamount").text() * 1);
         if (diff == 0) {
           $("#sidebar ul").show();
         }
         $("#stmtdiff").html(diff.toFixed(2));
         diff = $("#p"+trid).html();
         diff = (diff * 1) + ($("#stmttxnamount").text() * 1);
         $("#stmtpaycodes").val("6000").attr("selected",true);
       }
       else {
         var purtype = "new inv";
         if ($("#stmtinccodes").val() == "4310") {
           purtype = "intr";
         }
         $("<tr></tr>").html("<td style=\'display:none;\'>"+$("#stmtcusid").val()+"</td><td style=\'display:none;\'>"+purtype+"</td><td nowrap=\'nowrap\'>"+$("#stmtinctxndate").val()+"</td><td>"+document.getElementById("stmtvatrate").value+"</td><td>"+$("#stmtinccodes").val()+"</td><td>"+$("#stmt_cus_id").val()+"</td><td>"+$("#stmtdesc").val()+"</td><td>"+$("#stmttxnamount").text()+"</td><td style=\'display:none;\'>"+$("#stmtvat").text()+"</td><td style=\'display:none;\'>"+$("#stmtcusref").val()+"</td><td style=\'display:none;\'>"+$("#stmtitem_cat").val()+"</td><td onclick=\"revert(\'0\',$(this),\'"+trid+"\');\"><img src=\'/icons/delete.png\' width=\'12\' height=\'12\' alt=\'Delete\'/></td>").appendTo("#"+trid);
         var diff = document.getElementById("stmtdiff").innerHTML;
         diff = (diff * 1) - ($("#stmttxnamount").text() * 1);
         if (diff == 0) {
           $("#sidebar ul").show();
         }
         $("#stmtdiff").html(diff.toFixed(2));
         diff = $("#p"+trid).html();
         diff = (diff * 1) - ($("#stmttxnamount").text() * 1);
         $("#stmtinccodes").val("4300").attr("selected",true);
       }
       $("#p"+trid).html(diff.toFixed(2));
       $("#stmt_cus_id").val("");
       $("#stmtcusid").val("0");
       $("#stmtcusref").val("");
       $("#stmtitem_cat").val("");
       $(this).dialog("close");
     }
   }, 
  "Cancel": function() {
       $("#stmt_cus_id").val("");
       $("#stmtcusid").val("0");
       $("#stmtcusref").val("");
       $("#stmtitem_cat").val("");
       $(this).dialog("close");
     } 
  }
}); 
  $(".draggable").draggable({
	helper: "clone"
  });
  $(".droppable").droppable({
    accept: ".draggable",
    drop: function(event,ui) {
      var invvalue = ($(ui.draggable).find(":nth-child(8)").last().text() * 1);
      var stmtvalue = ($("#p"+$(this).attr("id")).html() * 1);

      if ($(this).attr("id") != "bnk0" && ((/^-/.test(invvalue) && !/^-/.test(stmtvalue)) || (! /^-/.test(invvalue) && /^-/.test(stmtvalue)))) {
        ui.draggable.draggable( "option", "revert", true );
        alert("Not a matching Credit/Debit");
      }
      else {
        $( this ).find( ".placeholder").remove();
        $("<tr></tr>").html( ui.draggable.html()+"<td onclick=\"revert(\'"+ui.draggable.attr("id")+"\',$(this),\'"+$(this).attr("id")+"\');\"><img src=\'/icons/delete.png\' width=\'12\' height=\'12\' alt=\'Delete\'/></td>" ).appendTo( this );

        var invdiff = (invvalue - stmtvalue).toFixed(2)
	if ($(this).attr("id") != "bnk0" && ((invvalue >= 0 && invdiff > 0) || (invvalue < 0 && invdiff < 0))) {
          $(ui.draggable).find(":nth-child(8)").text(invdiff);
          ui.draggable.draggable( "option", "revert", true );
          invvalue = (invvalue - invdiff).toFixed(2);
          $(this).find(":nth-child(8)").last().text(invvalue);
        }
        else {
          ui.draggable.draggable( "option", "revert", false );
          ui.draggable.draggable("disable");
        }
        var diff = ($("#stmtdiff").html() * 1);
        diff = (diff * 1) - (invvalue * 1);
        if (diff == 0) {
          $("#sidebar ul").show();
        }
        $("#stmtdiff").html(diff.toFixed(2));
        diff = $("#p"+$(this).attr("id")).html();
        diff = (diff * 1) - (invvalue * 1);
        $("#p"+$(this).attr("id")).html(diff.toFixed(2));
        if ($(this).find(":nth-child(2)").text() == "pay") {
          $(this).find(":nth-child(3)").text(($("#tr"+$(this).attr("id")).find(":nth-child(1)").first().text()));
        }
        return false;
      }
    }
  });
});
function change_date(obj,id,olddate,initval) {
  if ($(obj).parent().find(":last-child").text() == initval) {
    $(obj).addClass("error");
    document.getElementById("cd_id").value = id;
    document.getElementById("newdate").value = olddate;
    $("#changedate").dialog("open");
  }
  else {
    $("#dialog").html("You cannot change the date of a transaction that is (part) reconciled.");
    $("#dialog").dialog("open");
  }
}
function revert(id,el,dropid) {
  var diff = ($("#stmtdiff").html() * 1);
  var dropvalue = (el.parent().find(":nth-child(8)").last().text() * 1);
  var stmtremainder = ($("#p"+dropid).html() * 1);
  diff = (diff * 1) + (dropvalue * 1);
  $("#stmtdiff").html(diff.toFixed(2));
  diff = (dropvalue * 1) + (stmtremainder * 1);
  $("#p"+dropid).html(diff.toFixed(2));
  if (id != "0") {
    var newvalue;
    var invvalue = ($("#"+id).find(":nth-child(8)").text() * 1);
    if (invvalue != dropvalue) {
      newvalue = ($("#"+id).find(":nth-child(8)").text() * 1) + (dropvalue * 1);
    }
    else {
      newvalue = ($("#"+id).find(":nth-child(8)").text() * 1);
    }
    newvalue = newvalue.toFixed(2);
    $("#"+id).find(":nth-child(8)").text(newvalue);
    $("#"+id).draggable(\'enable\');
  }
  if (el.parent().parent().children().length < 2) {
    el.parent().replaceWith("<tr class=\'placeholder\'><td colspan=\'4\'></td></tr>");
  }
  else {
    el.parent().remove();
  }
}
function matchit(obj) {
  if ($(obj).find(":nth-child(4)").text() == "0.00") {
    alert("Already fully matched");
  }
  else {
    var trid = $(obj).attr("id").replace("trbnk","bnk");
    document.getElementById("stmtdropid").value = trid;
    if (/^-/.test($(obj).find(":nth-child(4)").text())) {
      $("#stmtmatch").dialog({title:"Money Out"});
      $("#stmtpaytxndate").val($(obj).find(":first").text());
      $("#stmtpaycodegp").show();
      $("#stmtinccodegp").hide();
      $("#stmtcusnametype").text("Supplier");
      $("#stmtpaytype").text("Amount Paid");
      $("#stmtcustype").val("Suppliers");
      var txnamt = (0 - ($(obj).find(":nth-child(4)").text() * 1)).toFixed(2);
    }
    else {
      $("#stmtmatch").dialog({title:"Money In"});
      $("#stmtinctxndate").val($(obj).find(":first").text());
      $("#stmtinccodegp").show();
      $("#stmtpaycodegp").hide();
      $("#stmtcusnametype").text("Customer");
      $("#stmtpaytype").text("Amount Received");
      $("#stmtcustype").val("Customers");
      var txnamt = (($(obj).find(":nth-child(4)").text() * 1)).toFixed(2);
    }
    $("#stmttxnamount").text(txnamt);
    calc_stmtvat();
    $("#stmtdesc").val($(obj).find(":nth-child(2)").text());
    $("#stmtmatch").dialog("open");
  }
}
function calc_stmtvat() {
  var totamt = ($("#stmttxnamount").text() * 1);
  var vat = (document.getElementById("stmtvatrate").value * 1);
  var vatdiv = vat + 1;
  var vatvalue = (totamt * vat / vatdiv).toFixed(2);
  $("#stmtvat").text(vatvalue);
  var netamt = totamt - vatvalue;
  $("#stmtnetamt").html("(Net = " + netamt.toFixed(2) + ")");
}
function submitit() {
  var err = "";
  $("#dropblock span").each(function() {
    if (! /0.00/.test($(this).text())) {
      err = "Warning not all remaining values are zero";
    }
  });
  if (err.length > 0) {
    alert(err);
    return false;
  }
  else {
    $("#stmtdata").val($("#dropblock").html());
    return true;
  }
}
function save_wip() {
  $.post("/cgi-bin/fpa/save_wip.pl",{ "data" : escape($("#dropblock").html()) });
  alert("Your Work in Progress has been saved");
}
function get_wip() {
  $.get("/cgi-bin/fpa/get_wip.pl", function(data) {
    document.getElementById("hiddenblock").innerHTML = unescape(unescape(data));
  $("#hiddenblock table").each(function() {
     if (! /placeholder/.test($(this).html())) {
       var stmt_id = $(this).attr("id");
       $(this).find("tr").each(function () {
         var txntype = $(this).find("td:nth-child(2)").text();
         if (txntype == "vat") {
           txntype = "inv";
         }
         var txn_id = txntype+$(this).find("td:first-child").text();
         var txn_amt = $(this).find("td:nth-child(8)").text() * 1;
         var rem_amt =  $("#p"+stmt_id).text() * 1;

         if (rem_amt != 0) {
           var orig_amt =  $("#"+txn_id).find(":nth-child(8)").text() * 1;
           $("#p"+stmt_id).text((rem_amt-txn_amt).toFixed(2));

           if (orig_amt == txn_amt) {
             $("#"+txn_id).draggable("disable");
           }
           else {
             $("#"+txn_id).find(":nth-child(8)").text((orig_amt-rem_amt).toFixed(2));
           }
         }
       });
       $("#"+stmt_id).html($(this).html());
    }
  });
  });
}
function upd_vat(obj) {
  if (/1300|4310|6010/.test(obj.value)) {
    $("#stmt_cus_id").val("Bank");
    $("#stmtvatrate").val("0");
    calc_stmtvat();
  }
  else {
    if ($("#stmt_cus_id").val() == "Bank") {
      $("#stmt_cus_id").val("");
    }
    $("#stmtvatrate").val("0.2");
    calc_stmtvat();
  }
}
</script>'
};

print "Content-Type: text/html\n\n";

$tt->process('newrec2.tt',$Vars);

$dbh->disconnect;
exit;

