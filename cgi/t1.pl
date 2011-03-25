#!/usr/bin/perl

<<<<<<< HEAD
$Dataset = $ARGV[0];
$Indent_count = $ARGV[1];

$Tabs = "\t\t\t\t\t\t\t\t\t\t\t\t\t";

use DBI;
$dbh = DBI->connect("DBI:mysql:fpa");
$Datasets = $dbh->prepare("select * from $Dataset limit 1;");
$Datasets->execute;
$Fields = $Datasets->fetchrow_hashref;
$Datasets->finish;
$dbh->disconnect;

$Indent = substr($Tabs,0,$Indent_count);
print $Indent."<$Dataset>\n";

while (($Key,$Value) = each %$Fields) {
	print $Indent."\t<$Key>\n";
}
print $Indent."</$Dataset>\n";
=======
use DBI;
$dbh = DBI->connect("DBI:mysql:fpa");
$Reg_coms = $dbh->prepare("select reg2_id,com_id,comname from reg_coms where reg1_id=1 order by comname");
$Reg_coms->execute;
$Companies = $Reg_coms->fetchall_arrayref({});

for $i (0..$Reg_coms->rows - 1) {
print ${$Companies}[$i]->{comname}."\n";
}

$Reg_coms->finish;
$dbh->disconnect;
>>>>>>> e49f749c038c65536ed3be6a5c34d52aa0bee260

exit;
