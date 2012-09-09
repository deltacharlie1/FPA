#!/usr/bin/perl
#
#  Script to get data feed from affiliate window

use DBI;
$dbh = DBI->connect("DBI:mysql:fpa");
$dbh->STORE('PrintError',0);

 $Sts = $dbh->do("delete from adverts");

$Merchant = "";
$Grp = 0;
$Ctr = 0;

while (<>) {
        if (/merchant.+name=\"(.+)\"/) {
                ($Merchant) = $1;
                print "Merchant = $Merchant\n\n";
		$Grp = 0;
		$Ctr = 0;
        }
        else {
#                s/http:/https:/g;
                s/\&amp;/\&/g;
		s/\'/\\\'/g;

                ($Name) = $_ =~ /\<name\>(.*)\<\/name\>/;
                ($Track) = $_ =~ /\<awTrack\>(.*)\<\/awTrack\>/;
                ($Thumb) = $_ =~ /\<awThumb\>(.*)\<\/awThumb\>/;
                ($Image) = $_ =~ /\<awImage\>(.*)\<\/awImage\>/;
		($Cat) = $_ =~ /\<awCat\>(.*)\<\/awCat\>/;
                ($Price) = $_ =~ /\<buynow\>(.*)\<\/buynow\>/;
                $Thumb =~ s/http:/https:/;
		$Cat = $Cat || 'Hot Deals';
                if ($Name && $Track && $Thumb) {
                        $Sts = $dbh->do("insert into adverts (merchant,name,track,thumb,image,price,cat,grp) values ('$Merchant','$Name','$Track','$Thumb','$Image','$Price','$Cat',$Grp)");
			$Ctr++;
			if ($Ctr > 11) {
				$Ctr = 0;
				$Grp++;
			}
                }
        }
}
$dbh->disconnect;
exit;

