sub display_adverts {
        my $Ads = $dbh->prepare("select name,track,thumb,image,price,cat from adverts where grp=$COOKIE->{NEXT_AD} limit 32");
#        my $Ads = $dbh->prepare("select name,track,thumb,image,price,cat from adverts where merchant in ('Dealtastic','Groupon') limit 32");
        $Ads->execute;
        $Adverts = $Ads->fetchall_arrayref({});
        my $Ads = $dbh->prepare("select name,track,thumb,image,price,cat from adverts where merchant in ('Dealtastic','Groupon') limit 32");
        $Ads->execute;
        while (@Ad = $Ads->fetchrow) {
		$COOKIE->{adv1} .=<<EOD;
            <li>
              <div style="float:left;padding-left:5px;width:70px;"><a href="$Ad[1]" target="_blank"><img src="$Ad[2]" width="70" height="70"></a></div>
              <div style="position:relative;float:left;padding:3px 0px 0 5px;width:125px;">
                <div style="width:115px;clear:both;display:block;padding:0px 4px 0 0;font-size:0.6em;font-weight:normal;text-transform:none;">$Ad[0]</div>
                <div style="position:absolute;top:40px;width:120px;">
                  <div style="float:right;padding:5px 0 0 0px;"><a href="$Ad[1]" target="_blank"><img src="/icons/buy_now_5.gif" border="0"></a></div>
                  <div style="float:left;padding-top:8px;text-align:center;">&pound;$Ad[4]</div>
                </div>
              </div>
            </li>
EOD
	}
        $Ads->finish;
}
1;
