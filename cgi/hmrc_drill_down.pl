#!/usr/bin/perl

$ACCESS_LEVEL = 1;

#  script to display the VAT actually owed to HMRC 

use Checkid;
$COOKIE = &checkid($ENV{HTTP_COOKIE},$ACCESS_LEVEL);

use DBI;
$dbh = DBI->connect("DBI:mysql:$COOKIE->{DB}");
unless ($COOKIE->{NO_ADS}) {
	require "/usr/local/git/fpa/cgi/display_adverts.ph";
	&display_adverts();
}


$Buffer = $ENV{QUERY_STRING};

@pairs = split(/&/,$Buffer);

foreach $pair (@pairs) {

        ($Name, $Value) = split(/=/, $pair);

        $Value =~ tr/+/ /;
        $Value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C",hex($1))/eg;
        $Value =~ tr/\\\'//d;
        $FORM{$Name} = $Value;
}

if ($FORM{qstart} =~ /Up/i) { $FORM{qstart} = '01-Jan-10'; }
$FORM{qstart} = $FORM{qstart} || '01-Jan-10';
$FORM{qend} = $FORM{qend} || '31-Dec-29';

$Daterange = "acrprintdate>=str_to_date('$FORM{qstart}','%d-%b-%y') and acrprintdate<=str_to_date('$FORM{qend}','%d-%b-%y')";
use Template;
$tt = Template->new({
        INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
        WRAPPER => 'header.tt',
});

if ($COOKIE->{VAT} =~ /C/i) {		#  Cash Accounting

	if ($FORM{boxno} =~ /box1/i) {
		unless ($FORM{numrows}) {
			$Accruals = $dbh->prepare("select count(*),sum(acrvat) from vataccruals where (acrnominalcode='4000' or acrnominalcode like '43%') and vr_id=$FORM{vrid} and vataccruals.acct_id='$COOKIE->{ACCT}' and $Daterange");
			$Accruals->execute;
       			($FORM{numrows},$FORM{vattotal}) = $Accruals->fetchrow;
		        $FORM{offset} = 0;
		       	$FORM{rows} = 24;
		}
		$Accruals = $dbh->prepare("select date_format(acrprintdate,'%d-%b-%y') as vatdate, invcusname,invinvoiceno,acrtype,acrvat as acramt,inv_txns.inv_id as inv_id,journals.id as jou_id,joudesc,joujnlno from vataccruals left join inv_txns on (vataccruals.acrtxn_id=inv_txns.id and vataccruals.acct_id=inv_txns.acct_id and vataccruals.acrtype='S') left join invoices on (inv_txns.inv_id=invoices.id and inv_txns.acct_id=invoices.acct_id) left join journals on (vataccruals.acrtxn_id=journals.id and vataccruals.acct_id=journals.acct_id) where (acrnominalcode='4000' or acrnominalcode like '43%') and vr_id=$FORM{vrid} and vataccruals.acct_id='$COOKIE->{ACCT}' and $Daterange order by acrprintdate limit $FORM{offset},$FORM{rows}");
		$Accruals->execute;
		$Col_header = "VAT Due";
		$Page_title = "UK Sales VAT";
		$Template = "box";
	}
	elsif ($FORM{boxno} =~ /box2/i) {
		unless ($FORM{numrows}) {
			$Accruals = $dbh->prepare("select count(*),sum(acrvat) from vataccrual where acrnominalcode='4100' and vr_id=$FORM{vrid} and vataccruals.acct_id='$COOKIE->{ACCT}' and $Daterange");
			$Accruals->execute;
       			($FORM{numrows},$FORM{vattotal}) = $Accruals->fetchrow;
	        	$FORM{offset} = 0;
		       	$FORM{rows} = 24;
		}
		$Accruals = $dbh->prepare("select date_format(acrprintdate,'%d-%b-%y') as vatdate, invcusname,invinvoiceno,acrtype,acrvat as acramt,inv_txns.inv_id as inv_id,journals.id as jou_id,joudesc,joujnlno from vataccruals left join inv_txns on (vataccruals.acrtxn_id=inv_txns.id and vataccruals.acct_id=inv_txns.acct_id and vataccruals.acrtype='S') left join invoices on (inv_txns.inv_id=invoices.id and inv_txns.acct_id=invoices.acct_id) left join journals on (vataccruals.acrtxn_id=journals.id and vataccruals.acct_id=journals.acct_id) where acrnominalcode='4100' and vr_id=$FORM{vrid} and vataccruals.acct_id='$COOKIE->{ACCT}' and $Daterange order by acrprintdate limit $FORM{offset},$FORM{rows}");
		$Accruals->execute;
		$Col_header = "VAT Due";
		$Page_title = "EU Sales VAT";
		$Template = "box";
	}
	elsif ($FORM{boxno} =~ /box3/i) {
		unless ($FORM{numrows}) {
			$Accruals = $dbh->prepare("select count(*),sum(acrvat) from vataccruals where (acrnominalcode='4000' or acrnominalcode='4100' or acrnominalcode like '43%') and vr_id=$FORM{vrid} and vataccruals.acct_id='$COOKIE->{ACCT}' and $Daterange");
			$Accruals->execute;
       			($FORM{numrows},$FORM{vattotal}) = $Accruals->fetchrow;
		        $FORM{offset} = 0;
		       	$FORM{rows} = 24;
		}
		$Accruals = $dbh->prepare("select date_format(acrprintdate,'%d-%b-%y') as vatdate, invcusname,invinvoiceno,acrtype,acrvat as acramt,inv_txns.inv_id as inv_id,journals.id as jou_id,joudesc,joujnlno from vataccruals left join inv_txns on (vataccruals.acrtxn_id=inv_txns.id and vataccruals.acct_id=inv_txns.acct_id and vataccruals.acrtype='S') left join invoices on (inv_txns.inv_id=invoices.id and inv_txns.acct_id=invoices.acct_id) left join journals on (vataccruals.acrtxn_id=journals.id and vataccruals.acct_id=journals.acct_id) where (acrnominalcode='4000' or acrnominalcode='4100' or acrnominalcode like '43%') and vr_id=$FORM{vrid} and vataccruals.acct_id='$COOKIE->{ACCT}' and $Daterange order by acrprintdate limit $FORM{offset},$FORM{rows}");
		$Accruals->execute;
		$Col_header = "VAT Due";
		$Page_title = "Total UK/EU Sales VAT";
		$Template = "box";
	}
	elsif ($FORM{boxno} =~ /box4/i) {
		unless ($FORM{numrows}) {
			$Accruals = $dbh->prepare("select count(*),sum(acrvat) from vataccruals where (acrnominalcode like '10%' or  acrnominalcode like '15%' or (acrnominalcode>='5000' and acrnominalcode<'7500')) and vr_id=$FORM{vrid} and vataccruals.acct_id='$COOKIE->{ACCT}' and $Daterange and acrvat<0");
			$Accruals->execute;
       			($FORM{numrows},$FORM{vattotal}) = $Accruals->fetchrow;
			$FORM{vattotal} = 0 - $FORM{vattotal};
		        $FORM{offset} = 0;
		       	$FORM{rows} = 24;
		}
		$Accruals = $dbh->prepare("select date_format(acrprintdate,'%d-%b-%y') as vatdate, invcusname,invinvoiceno,acrtype,acrvat as acramt,inv_txns.inv_id as inv_id,journals.id as jou_id,joudesc,joujnlno from vataccruals left join inv_txns on (vataccruals.acrtxn_id=inv_txns.id and vataccruals.acct_id=inv_txns.acct_id and vataccruals.acrtype='P') left join invoices on (inv_txns.inv_id=invoices.id and inv_txns.acct_id=invoices.acct_id) left join journals on (vataccruals.acrtxn_id=journals.id and vataccruals.acct_id=journals.acct_id) where (acrnominalcode like '10%' or acrnominalcode like '15%' or (acrnominalcode>='5000' and acrnominalcode<'7500')) and vr_id=$FORM{vrid} and vataccruals.acct_id='$COOKIE->{ACCT}' and $Daterange and acrvat<0 order by acrprintdate limit $FORM{offset},$FORM{rows}");
		$Accruals->execute;
		$Col_header = "VAT Refund";
		$Page_title = "Purchases VAT";
		$Template = "box";
	}
	elsif ($FORM{boxno} =~ /box5/i) {
		unless ($FORM{numrows}) {
			$Accruals = $dbh->prepare("select count(*),sum(acrvat) from vataccruals where (acrnominalcode like '10%' or acrnominalcode like '15%' or acrnominalcode in ('4000','4100') or (acrnominalcode>='4300' and acrnominalcode<'7500')) and vr_id=$FORM{vrid} and vataccruals.acct_id='$COOKIE->{ACCT}' and $Daterange");
			$Accruals->execute;
       			($FORM{numrows},$FORM{vattotal}) = $Accruals->fetchrow;
	        	$FORM{offset} = 0;
		       	$FORM{rows} = 24;
		}
		$Accruals = $dbh->prepare("select date_format(acrprintdate,'%d-%b-%y') as vatdate, invcusname,invinvoiceno,acrtype,acrvat as acramt,inv_txns.inv_id as inv_id,journals.id as jou_id,joudesc,joujnlno from vataccruals left join inv_txns on (vataccruals.acrtxn_id=inv_txns.id and vataccruals.acct_id=inv_txns.acct_id and vataccruals.acrtype in ('S','P')) left join invoices on (inv_txns.inv_id=invoices.id and inv_txns.acct_id=invoices.acct_id) left join journals on (vataccruals.acrtxn_id=journals.id and vataccruals.acct_id=journals.acct_id) where (acrnominalcode like '10%' or acrnominalcode like '15%' or acrnominalcode in ('4000','4100') or (acrnominalcode>='4300' and acrnominalcode<'7500')) and vr_id=$FORM{vrid} and vataccruals.acct_id='$COOKIE->{ACCT}' and $Daterange order by acrprintdate limit $FORM{offset},$FORM{rows}");
		$Accruals->execute;
		$Page_title = "VAT due to/from HMRC";
		$Template = "box5";
	}	
	elsif ($FORM{boxno} =~ /box6/i) {
		unless ($FORM{numrows}) {
			$Accruals = $dbh->prepare("select count(*),sum(acrtotal) from vataccruals where acrnominalcode in ('4000','4100','4200') and vr_id=$FORM{vrid} and vataccruals.acct_id='$COOKIE->{ACCT}' and $Daterange");
			$Accruals->execute;
       			($FORM{numrows},$FORM{vattotal}) = $Accruals->fetchrow;
	        	$FORM{offset} = 0;
		       	$FORM{rows} = 24;
		}
		$Accruals = $dbh->prepare("select date_format(acrprintdate,'%d-%b-%y') as vatdate, invcusname,invinvoiceno,acrtype,acrvat as acramt,inv_txns.inv_id as inv_id,journals.id as jou_id,joudesc,joujnlno from vataccruals left join inv_txns on (vataccruals.acrtxn_id=inv_txns.id and vataccruals.acct_id=inv_txns.acct_id and vataccruals.acrtype='S') left join invoices on (inv_txns.inv_id=invoices.id and inv_txns.acct_id=invoices.acct_id) left join journals on (vataccruals.acrtxn_id=journals.id and vataccruals.acct_id=journals.acct_id) where acrnominalcode in ('4000','4100','4200') and vr_id=$FORM{vrid} and vataccruals.acct_id='$COOKIE->{ACCT}' and $Daterange order by acrprintdate limit $FORM{offset},$FORM{rows}");
		$Accruals->execute;
		$Col_header = "Sales Net";
		$Page_title = "Total Net Sales";
		$Template = "box";
	}
	elsif ($FORM{boxno} =~ /box7/i) {
		unless ($FORM{numrows}) {
			$Accruals = $dbh->prepare("select count(*),sum(acrtotal) from vataccruals where (acrnominalcode like '10%' or (acrnominalcode like '15%' or acrnominalcode>='5000' and acrnominalcode<'7500')) and vr_id=$FORM{vrid} and vataccruals.acct_id='$COOKIE->{ACCT}' and $Daterange");
			$Accruals->execute;
       			($FORM{numrows},$FORM{vattotal}) = $Accruals->fetchrow;
			$FORM{vattotal} = 0 - $FORM{vattotal};
		        $FORM{offset} = 0;
		       	$FORM{rows} = 24;
		}
		$Accruals = $dbh->prepare("select date_format(acrprintdate,'%d-%b-%y') as vatdate, invcusname,invinvoiceno,acrtype,acrvat as acramt,inv_txns.inv_id as inv_id,journals.id as jou_id,joudesc,joujnlno from vataccruals left join inv_txns on (vataccruals.acrtxn_id=inv_txns.id and vataccruals.acct_id=inv_txns.acct_id and vataccruals.acrtype='P') left join invoices on (inv_txns.inv_id=invoices.id and inv_txns.acct_id=invoices.acct_id) left join journals on (vataccruals.acrtxn_id=journals.id and vataccruals.acct_id=journals.acct_id) where (acrnominalcode like '10%' or acrnominalcode like '15%' or (acrnominalcode>='5000' and acrnominalcode<'7500')) and vr_id=$FORM{vrid} and vataccruals.acct_id='$COOKIE->{ACCT}' and $Daterange order by acrprintdate limit $FORM{offset},$FORM{rows}");
		$Accruals->execute;
		$Col_header = "Purchases Net";
		$Page_title = "Total Net Purchases";
		$Template = "box";
	}
}
else {			#  Standard Accunting Scheme

	if ($FORM{boxno} =~ /box1/i) {
		unless ($FORM{numrows}) {
			$Accruals = $dbh->prepare("select count(*),sum(acrvat) from vataccruals where (acrnominalcode='4000' or acrnominalcode like '43%') and vr_id=$FORM{vrid} and vataccruals.acct_id='$COOKIE->{ACCT}' and $Daterange");
			$Accruals->execute;
       			($FORM{numrows},$FORM{vattotal}) = $Accruals->fetchrow;
		        $FORM{offset} = 0;
		       	$FORM{rows} = 24;
		}
		$Accruals = $dbh->prepare("select date_format(acrprintdate,'%d-%b-%y') as vatdate,invcusname,invinvoiceno,acrtype,acrvat as acramt,invoices.id as inv_id,journals.id as jou_id,joudesc,joujnlno from vataccruals left join invoices on (vataccruals.acrtxn_id=invoices.id and vataccruals.acct_id=invoices.acct_id and vataccruals.acrtype='S') left join journals on (vataccruals.acrtxn_id=journals.id and vataccruals.acct_id=journals.acct_id) where (acrnominalcode='4000' or acrnominalcode like '43%') and vr_id=$FORM{vrid} and vataccruals.acct_id='$COOKIE->{ACCT}' and $Daterange order by acrprintdate limit $FORM{offset},$FORM{rows}");
		$Accruals->execute;
		$Col_header = "VAT Due";
		$Page_title = "UK Sales VAT";
		$Template = "box";
	}
	elsif ($FORM{boxno} =~ /box2/i) {
		unless ($FORM{numrows}) {
			$Accruals = $dbh->prepare("select count(*),sum(acrvat) from vataccruals where acrnominalcode='4100' and vr_id=$FORM{vrid} and vataccruals.acct_id='$COOKIE->{ACCT}' and $Daterange");
			$Accruals->execute;
       			($FORM{numrows},$FORM{vattotal}) = $Accruals->fetchrow;
	        	$FORM{offset} = 0;
		       	$FORM{rows} = 24;
		}
		$Accruals = $dbh->prepare("select date_format(acrprintdate,'%d-%b-%y') as vatdate,invcusname,invinvoiceno,acrtype,acrvat as acramt,invoices.id as inv_id,journals.id as jou_id,joudesc,joujnlno from vataccruals left join invoices on (vataccruals.acrtxn_id=invoices.id and vataccruals.acct_id=invoices.acct_id and vataccruals.acrtype='S') left join journals on (vataccruals.acrtxn_id=journals.id and vataccruals.acct_id=journals.acct_id) where acrnominalcode='4100' and vr_id=$FORM{vrid} and vataccruals.acct_id='$COOKIE->{ACCT}' and $Daterange order by acrprintdate limit $FORM{offset},$FORM{rows}");
		$Accruals->execute;
		$Col_header = "VAT Due";
		$Page_title = "EU Sales VAT";
		$Template = "box";
	}
	elsif ($FORM{boxno} =~ /box3/i) {
		unless ($FORM{numrows}) {
			$Accruals = $dbh->prepare("select count(*),sum(acrvat) from vataccruals where (acrnominalcode='4000' or acrnominlcode='4100' or acrnominalcode like '43%') and vr_id=$FORM{vrid} and vataccruals.acct_id='$COOKIE->{ACCT}' and $Daterange");
			$Accruals->execute;
       			($FORM{numrows},$FORM{vattotal}) = $Accruals->fetchrow;
		        $FORM{offset} = 0;
		       	$FORM{rows} = 24;
		}
		$Accruals = $dbh->prepare("select date_format(acrprintdate,'%d-%b-%y') as vatdate,invcusname,invinvoiceno,acrtype,acrvat as acramt,invoices.id as inv_id,journals.id as jou_id,joudesc,joujnlno from vataccruals left join invoices on (vataccruals.acrtxn_id=invoices.id and vataccruals.acct_id=invoices.acct_id and vataccruals.acrtype='S') left join journals on (vataccruals.acrtxn_id=journals.id and vataccruals.acct_id=journals.acct_id) where (acrnominalcode='4000' or acrnominalcode='4100' or acrnominalcode like '43%') and vr_id=$FORM{vrid} and vataccruals.acct_id='$COOKIE->{ACCT}' and $Daterange order by acrprintdate limit $FORM{offset},$FORM{rows}");
		$Accruals->execute;
		$Col_header = "VAT Due";
		$Page_title = "Total EU/UK Sales VAT";
		$Template = "box";
	}
	elsif ($FORM{boxno} =~ /box4/i) {
		unless ($FORM{numrows}) {
			$Accruals = $dbh->prepare("select count(*),sum(acrvat) from vataccruals where (acrnominalcode like '10%' or acrnominalcode like '15%' or (acrnominalcode>='5000' and acrnominalcode<'7500')) and vr_id=$FORM{vrid} and vataccruals.acct_id='$COOKIE->{ACCT}' and $Daterange");
			$Accruals->execute;
       			($FORM{numrows},$FORM{vattotal}) = $Accruals->fetchrow;
			$FORM{vattotal} = 0 - $FORM{vattotal};
		        $FORM{offset} = 0;
		       	$FORM{rows} = 24;
		}
		$Accruals = $dbh->prepare("select date_format(acrprintdate,'%d-%b-%y') as vatdate,invcusname,invinvoiceno,acrtype,acrvat as acramt,invoices.id as inv_id,journals.id as jou_id,joudesc,joujnlno from vataccruals left join invoices on (vataccruals.acrtxn_id=invoices.id and vataccruals.acct_id=invoices.acct_id and vataccruals.acrtype='P') left join journals on (vataccruals.acrtxn_id=journals.id and vataccruals.acct_id=journals.acct_id) where (acrnominalcode like '10%' or acrnominalcode like '15%' or (acrnominalcode>='5000' and acrnominalcode<'7500')) and vr_id=$FORM{vrid} and vataccruals.acct_id='$COOKIE->{ACCT}' and $Daterange order by acrprintdate limit $FORM{offset},$FORM{rows}");
		$Accruals->execute;
		$Col_header = "VAT Refund";
		$Page_title = "Purchases VAT";
		$Template = "box";
	}
	elsif ($FORM{boxno} =~ /box5/i) {
		unless ($FORM{numrows}) {
			$Accruals = $dbh->prepare("select count(*),sum(acrvat) from vataccruals where (acrnominalcode like '10%' or acrnominalcode like '15%' or acrnominalcode in ('4000','4100') or (acrnominalcode>='4300' and acrnominalcode<'7500')) and vr_id=$FORM{vrid} and vataccruals.acct_id='$COOKIE->{ACCT}' and $Daterange");
			$Accruals->execute;
       			($FORM{numrows},$FORM{vattotal}) = $Accruals->fetchrow;
	        	$FORM{offset} = 0;
		       	$FORM{rows} = 24;
		}
		$Accruals = $dbh->prepare("select date_format(acrprintdate,'%d-%b-%y') as vatdate,invcusname,invinvoiceno,acrtype,acrvat as acramt,invoices.id as inv_id,journals.id as jou_id,joudesc,joujnlno from vataccruals left join invoices on (vataccruals.acrtxn_id=invoices.id and vataccruals.acct_id=invoices.acct_id and vataccruals.acrtype in ('S','P')) left join journals on (vataccruals.acrtxn_id=journals.id and vataccruals.acct_id=journals.acct_id) where (acrnominalcode  like '10%' or acrnominalcode like '15%' or acrnominalcode in ('4000','4100') or (acrnominalcode>='4300' and acrnominalcode<'7500')) and vr_id=$FORM{vrid} and vataccruals.acct_id='$COOKIE->{ACCT}' and $Daterange order by acrprintdate limit $FORM{offset},$FORM{rows}");
		$Accruals->execute;
		$Page_title = "VAT due to/from HMRC";
		$Template = "box5";
	}	
	elsif ($FORM{boxno} =~ /box6/i) {
		unless ($FORM{numrows}) {
			$Accruals = $dbh->prepare("select count(*),sum(acrtotal) from vataccruals where acrnominalcode in ('4000','4100','4200') and vr_id=$FORM{vrid} and vataccruals.acct_id='$COOKIE->{ACCT}' and $Daterange");
			$Accruals->execute;
       			($FORM{numrows},$FORM{vattotal}) = $Accruals->fetchrow;
	        	$FORM{offset} = 0;
		       	$FORM{rows} = 24;
		}
		$Accruals = $dbh->prepare("select date_format(acrprintdate,'%d-%b-%y') as vatdate,invcusname,invinvoiceno,acrtype,acrtotal as acramt,invoices.id as inv_id,journals.id as jou_id,joudesc,joujnlno from vataccruals left join invoices on (vataccruals.acrtxn_id=invoices.id and vataccruals.acct_id=invoices.acct_id and vataccruals.acrtype='S') left join journals on (vataccruals.acrtxn_id=journals.id and vataccruals.acct_id=journals.acct_id) where acrnominalcode in ('4000','4100','4200') and vr_id=$FORM{vrid} and vataccruals.acct_id='$COOKIE->{ACCT}' and $Daterange order by acrprintdate limit $FORM{offset},$FORM{rows}");
		$Accruals->execute;
		$Col_header = "Sales Net";
		$Page_title = "Total Net Sales";
		$Template = "box";
	}
	elsif ($FORM{boxno} =~ /box7/i) {
		unless ($FORM{numrows}) {
			$Accruals = $dbh->prepare("select count(*),sum(acrtotal) from vataccruals where (acrnominalcode like '10%' or acrnominalcode like '15%' or (acrnominalcode>='5000' and acrnominalcode<'7500')) and vr_id=$FORM{vrid} and vataccruals.acct_id='$COOKIE->{ACCT}' and $Daterange");
			$Accruals->execute;
       			($FORM{numrows},$FORM{vattotal}) = $Accruals->fetchrow;
			$FORM{vattotal} = 0 - $FORM{vattotal};
		        $FORM{offset} = 0;
		       	$FORM{rows} = 24;
		}
		$Accruals = $dbh->prepare("select date_format(acrprintdate,'%d-%b-%y') as vatdate,invcusname,invinvoiceno,acrtype,acrtotal as acramt,invoices.id as inv_id,journals.id as jou_id,joudesc,joujnlno from vataccruals left join invoices on (vataccruals.acrtxn_id=invoices.id and vataccruals.acct_id=invoices.acct_id and vataccruals.acrtype='S') left join journals on (vataccruals.acrtxn_id=journals.id and vataccruals.acct_id=journals.acct_id) where (acrnominalcode like '10%' or acrnominalcode like '15%' or (acrnominalcode>='5000' and acrnominalcode<'7500')) and vr_id=$FORM{vrid} and vataccruals.acct_id='$COOKIE->{ACCT}' and $Daterange order by acrprintdate limit $FORM{offset},$FORM{rows}");
		$Accruals->execute;
		$Col_header = "Purchases Net";
		$Page_title = "Total Net Purchases";
		$Template = "box";
	}
}
#  Get the VAT accruals and related invoice data

$Accrual = $Accruals->fetchall_arrayref({}),

$Vars = {
	title => 'Accounts - VAT drill down',
	cookie => $COOKIE,
	pagetitle => $Page_title,
       	numrows => $FORM{numrows},
        offset => $FORM{offset},
	rows => $FORM{rows},
	vattotal => $FORM{vattotal},
	entries => $Accrual,
        javascript => '<script type="text/javascript">
function redisplay(action) {

  numrows = ' . $FORM{numrows} . ';
  offset = ' . $FORM{offset} . ';
  rows = ' . $FORM{rows} . ';

  if (document.getElementById("goto").value.length > 0) {
    offset = (document.getElementById("goto").value - 2) * rows;
    if (offset >= numrows) {
      offset = numrows - (numrows % rows);
    }
  }

  switch(action) {

    case "first":
      offset = 0;
      break;

    case "back":
      offset - rows < 0 ? offset = 0 : offset = offset - rows;
      break;

    case "next":
      offset + rows < numrows ? offset = offset + rows : offset = offset;
      break;

    case "last":
      offset = numrows - (numrows % rows);
      break;
  }

  location.href = "/cgi-bin/fpa/hmrc_drill_down.pl?vattotal=' . $FORM{vattotal} . '&boxno=' . $FORM{boxno} . '&vrid=" + ' . $FORM{vrid} . ' + "&numrows=" + numrows + "&offset=" + offset + "&rows=" + rows;
}
</script>'
};

$Accruals->finish;
print "Content-Type: text/html\n\n";
$tt->process("${Template}_drill_down.tt",$Vars);
$dbh->disconnect;
exit;

