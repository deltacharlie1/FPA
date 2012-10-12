#!/usr/bin/perl

# unlink /usr/local/git/fpa/other/datafeed_125207.xml;

#  Get the day of the week

$DOW = `date +%u`;
chomp($DOW);

# Horizontal Adverts

#  Dealtastic

$AWH[0]='177,196,379,648/mid/2641';

#  Gizoo

$AWH[1]='66,128,130,133,212,207,209,210,211,4,5,10,11,537,13,15,14,18,6,551,20,21,22,23,24,25,26,27,7,30,29,32,619,34,8,35,618,40,38,42,43,9,45,46,651,47,49,50,379,648,570,411,415,418,474,465,466,495,507,563/mid/1965';

#  Cadbury

$AWH[2]='437/mid/736';

#  Gadgets.co.uk

$AWH[3]='177,196,379,648,181,645,384,387,646,598,611,391,393,647,395,631,602,570,600,405,187,411,412,413,414,415,416,417,649,418,419,420/mid/381';

#  BBC

$AWH[4]='97,98,142,144,146,129,595,539,147,149,613,626,135,163,168,159,169,161,167,170,137,171,548,174,183,178,179,175,172,623,139,614,189,194,141,205,198,206,203,208,199,204,201,634,230,231,538,235,550,240,585,239,241,556,245,242,521,576,575,577,579,540,542,544,546,547/mid/3712';

#  London Theatre

$AWH[5]='588/mid/610';

#  InterRose

$AWH[6]='393/mid/129';

$Ctr = 0;
$Ads = 0;
$File = 0;

open(FILE,">/usr/local/git/fpa/htdocs/lib/adverts/horiz/Advert$File.tt");

$merchant = $DOW;

while ($File < 20) {
	$url = $AWH[$merchant];

	`wget -O /usr/local/git/fpa/other/awin.zip http://datafeed.api.productserve.com/datafeed/download/apikey/b256d8c0d1c220dd55a3382fd1b370e5/cid/$url/columns/merchant_id,merchant_name,aw_product_id,product_name,category_id,category_name,aw_deep_link,aw_image_url,search_price,currency,aw_thumb_url/format/xml/compression/zip/`;

	`unzip -o -p /usr/local/git/fpa/other/awin.zip > /usr/local/git/fpa/other/datafeed_125207.xml`;

	open(XMLFILE,'</usr/local/git/fpa/other/datafeed_125207.xml');
	while (<XMLFILE>) {

	        s/\&amp;/\&/g;
	        s/\'/\\\'/g;

	        ($Name) = $_ =~ /\<name\>(.*)\<\/name\>/;
	        if (length($Name) > 50) {
               		$Name = substr($Name,0,45)." ...";
	        }
	        ($Desc) = $_ =~ /\<desc\>(.*)\<\/desc\>/;
	        ($Track) = $_ =~ /\<awTrack\>(.*)\<\/awTrack\>/;
	        ($Thumb) = $_ =~ /\<awThumb\>(.*)\<\/awThumb\>/;
	        ($Image) = $_ =~ /\<awImage\>(.*)\<\/awImage\>/;
	        ($Cat) = $_ =~ /\<awCat\>(.*)\<\/awCat\>/;
	        ($Price) = $_ =~ /\<buynow\>(.*)\<\/buynow\>/;
	        $Thumb =~ s/http:/https:/;
	        $Cat = $Cat || 'Hot Deals';
	        if ($Name && $Track && $Thumb) {

	                print FILE <<EOD;
            <div class="h_l"><a href="$Track" target="_blank"><img src="$Thumb" width="70" height="70"></a></div>
            <div class="h_r">
              <div class="h_n">$Name</div>
              <div class="h_g">
                <div class="h_m"><a href="$Track" target="_blank"><img src="/icons/buy_now_5.gif" border="0"></a></div>
                <div class="h_p">&pound;$Price</div>
              </div>
            </div>
EOD

               		$Ctr++;

	                if ($Ctr > 11) {

               		        close(FILE);
	                        $File++;

				last if $File > 20;

	                        $Ctr = 0;
               		        open(FILE,">/usr/local/git/fpa/htdocs/lib/adverts/horiz/Advert$File.tt");
	                }
	        }
	}
	close(XMLFILE);

	$merchant++;
	if ($merchant > 6) { $merchant = 0; }
}
close(FILE);
close(XMLFILE);

print "\n\n~~ Now doing Vertical Ads ##\n\n";

#  Now do Vertical Ads

#  PC World

$AWV[0] = '63,80,82,64,83,84,85,212,210,213,217,229,596/mid/1598';

#  Ryman

$AWV[1] = '448,452,450,464,596,356,357/mid/3326';

#  DIY Tools

$AWV[2] = '428,474,475,476,477,596/mid/513';

#  Electical Discount

$AWV[3] = '4,5,10,11,537,13,15,14,18,6,551,20,21,22,23,24,25,26,27,7,30,29,32,619,34,8,35,618,40,38,42,43,9,45,46,651,47,49,50,361,633,362,366,367,368,371,369,363,372,373,374,377,375,536,535,364,378,380,381,365,383,385,390,392,394,396,397,399,402,404,406,407/mid/1311';

#  PC World (Faxes etc)

$AWV[4] = '595,347,348,354,350,351,349,355,356,357,358,359,563/mid/1598';

#UKHosts4U

$AWV[5] = '94/mid/1757';

#  Vistaprint

$AWV[6] = '181,645,384,387,646,598,611,391,393,647,395,631,602,570,600,405,596/mid/282';


$Ctr = 0;
$Ads = 0;
$File = 0;

open(FILE,">/usr/local/git/fpa/htdocs/lib/adverts/vert/Advert$File.tt");

$merchant = $DOW;

while ($File < 20) {
	$url = $AWV[$merchant];

	`wget -O /usr/local/git/fpa/other/awin.zip http://datafeed.api.productserve.com/datafeed/download/apikey/b256d8c0d1c220dd55a3382fd1b370e5/cid/$url/columns/merchant_id,merchant_name,aw_product_id,product_name,category_id,category_name,aw_deep_link,aw_image_url,search_price,currency,aw_thumb_url/format/xml/compression/zip/`;

	`unzip -o -p /usr/local/git/fpa/other/awin.zip > /usr/local/git/fpa/other/datafeed_125207.xml`;

	open(XMLFILE,'</usr/local/git/fpa/other/datafeed_125207.xml');
	while (<XMLFILE>) {

	        s/\&amp;/\&/g;
	        s/\'/\\\'/g;

	        ($Name) = $_ =~ /\<name\>(.*)\<\/name\>/;
	        if (length($Name) > 50) {
               		$Name = substr($Name,0,45)." ...";
	        }
	        ($Desc) = $_ =~ /\<desc\>(.*)\<\/desc\>/;
	        ($Track) = $_ =~ /\<awTrack\>(.*)\<\/awTrack\>/;
	        ($Thumb) = $_ =~ /\<awThumb\>(.*)\<\/awThumb\>/;
	        ($Image) = $_ =~ /\<awImage\>(.*)\<\/awImage\>/;
	        ($Cat) = $_ =~ /\<awCat\>(.*)\<\/awCat\>/;
	        ($Price) = $_ =~ /\<buynow\>(.*)\<\/buynow\>/;
	        $Thumb =~ s/http:/https:/;
	        $Cat = $Cat || 'Hot Deals';
	        if ($Name && $Track && $Thumb) {
	                print FILE <<EOD;
        <div style="width:152px;height:75px;padding:5px;">
          <div class="v_l">
            <a href="$Track" target="_blank"><img src="$Thumb" width="70" height="70"></a>
          </div>
          <div class="v_r">
            <div class="v_p">&pound;$Price</div>
            <div class="v_m"><a href="$Track" target="_blank"><img src="/icons/buy_now_5.gif" border="0"></a></div>
          </div>
        </div>
        <div class="v_n">$Name</div>
EOD

               		$Ctr++;

	                if ($Ctr > 11) {

               		        close(FILE);
	                        $File++;

				exit if $File > 20;

	                        $Ctr = 0;
               		        open(FILE,">/usr/local/git/fpa/htdocs/lib/adverts/vert/Advert$File.tt");
	                }
	        }
	}
	close(XMLFILE);

	$merchant++;
	if ($merchant > 6) { $merchant = 0; }
}
close(FILE);
close(XMLFILE);

