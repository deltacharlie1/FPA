sub display_adverts {
	$Adverts = $dbh->prepare("select adv1,adv2,adv3 from adverts where sort=$COOKIE->{NEXT_AD}");
	$Adverts->execute;
	($COOKIE->{adv1},$COOKIE->{adv2},$COOKIE->{adv3}) = $Adverts->fetchrow;
	$Adverts->finish;
}
1;
