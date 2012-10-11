sub display_adverts {
        my $Ads = $dbh->prepare("select name,track,thumb,image,price,cat from adverts where merchant like 'Cartr%' limit 32");
#        my $Ads = $dbh->prepare("select name,track,thumb,image,price,cat from adverts where merchant in ('Dealtastic','Groupon') limit 32");
        $Ads->execute;
        $Adverts = $Ads->fetchall_arrayref({});
        my $Ads = $dbh->prepare("select name,track,thumb,image,price,cat from adverts where merchant like 'Choice%' limit 32");
        $Ads->execute;
        while (@Ad = $Ads->fetchrow) {
		$COOKIE->{adv1} .=<<EOD;
            <li>
              <div class="h_l"><a href="$Ad[1]" target="_blank"><img src="$Ad[2]" width="70" height="70"></a></div>
              <div class="h_r">
                <div class="h_n">$Ad[0]</div>
                <div class="h_g">
                  <div class="h_m"><a href="$Ad[1]" target="_blank"><img src="/icons/buy_now_5.gif" border="0"></a></div>
                  <div class="h_p">&pound;$Ad[4]</div>
                </div>
              </div>
            </li>
EOD
	}
        $Ads->finish;
}
1;
