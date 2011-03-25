#!/usr/bin/perl
use DBI;
$dbh = DBI->connect("DBI:mysql:fpa");

        open(TEMP,">",\$Input_file);

	format TEMP_TOP = 
                  VAT Period:  @<<<<<<<<<< to   @<<<<<<<<<<
$FORM{qstart},$FORM{qend}

Report Date: @<<<<<<<<<<                                       Page No: @<<<
$Report_date,$%

VAT Date    Detail                                   VAT Output  VAT Input
---------------------------------------------------------------------------
.

	format TEMP = 
@<<<<<<<<<  @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<  @>>>>>>>>  @>>>>>>>>
$Accrual[0],$Accrual[1],$Output,$Input
.

       	$Accruals = $dbh->prepare("select date_format(acrprintdate,'%d-%b-%y') as vatdate, invcusname,invinvoiceno,acrtype,acrvat as acramt,invoices.id as inv_id from vataccruals,invoices where vataccruals.acrtxn_id=invoices.id and vataccruals.acct_id=invoices.acct_id and vr_id=0 and vataccruals.acct_id='5+5' order by acrprintdate");

        $Accruals->execute;
	while (@Accrual = $Accruals->fetchrow) {
		$Accrual[4] =~ tr/-//d;
		if ($Accrual[4] > 0) {
			$Accrual[1] = substr($Accrual[1],0,21)." (Invoice - $Accrual[2])";
			if ($Accrual[3] =~ /P/i) {
				$Input = $Accrual[4];
				$Output = "";
				$Tot_input += $Input;
			}
			else {
				$Output = $Accrual[4];
				$Input = "";
				$Tot_output += $Output;
			}
			write TEMP;
		}
	}
	print TEMP "---------------------------------------------------------------------------\n";
	printf TEMP "            Totals                                    %9.2f  %9.2f\n",$Tot_output,$Tot_input;
	print TEMP "===========================================================================\n";
        close(TEMP);

        use Template;
        $tt = Template->new({
                INCLUDE_PATH => ['.','/usr/local/httpd/htdocs/fpa/lib'],
                WRAPPER => 'header.tt',
        });
        print "Content-Type:text/html\n\n";
        $Vars = { cookie => $COOKIE,
          data => $Input_file
        };
        $tt->process('print_listing.tt',$Vars);

$Accruals->finish;

$dbh->disconnect;
exit;
