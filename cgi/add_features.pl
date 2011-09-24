#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to display the main cover sheet updating screen

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");
unless ($COOKIE->{NO_ADS}) {
	require "/usr/local/git/fpa/cgi/display_adverts.ph";
	&display_adverts();
}


($Reg_id,$Com_id) = split(/\+/,$COOKIE->{ACCT});
$Companies = $dbh->prepare("select date_format(compt_logo,'%d-%b-%y') as compt_logo,comadd_user,date_format(comno_ads,'%d-%b-%y') as comno_ads,comuplds,date_format(comkeep_recs,'%d-%b-%y') as comkeep_recs,date_format(comadvertise,'%d-%b-%y') as comadvertise from companies where reg_id=$Reg_id and id=$Com_id");
$Companies->execute;
$Company = $Companies->fetchrow_hashref;
$Companies->finish;
$dbh->disconnect;

use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
        WRAPPER => 'header.tt',
});

$Vars = {
        title => 'Accounts - Additional Features',
	cookie => $COOKIE,
	company => $Company,
	focus => 'compt_logo',
        javascript => '<script type="text/javascript" src="/js/jquery-form.js"></script> 
<script type="text/javascript">
function calc_total() {
  var add_total = 0;
  if ($("#compt_logo").attr("checked")) {
    add_total = add_total + 30;
  }
  add_total = add_total + $("#comadd_user").val() * 50;
  if ($("#comno_ads").attr("checked")) {
    add_total = add_total + 50;
  }
  if ($("#comuplds").attr("checked")) {
    add_total = add_total + 50;
  }
  if ($("#comkeep_recs").attr("checked")) {
    add_total = add_total + 30;
  }
  if ($("#comadvertise").attr("checked")) {
    add_total = add_total + 30;
  }
  if (add_total == 0) {
    document.getElementById("additions_total").innerHTML = add_total + ".00";
  }
  else {
    document.getElementById("additions_total").innerHTML = "&pound;" + add_total + ".00";
  }
}
</script>',
};

print "Content-Type: text/html\n\n";
$tt->process('add_features.tt',$Vars);
exit;

