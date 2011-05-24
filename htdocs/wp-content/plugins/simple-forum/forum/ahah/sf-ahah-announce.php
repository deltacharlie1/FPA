<?php
/*
Simple:Press
Ahah call for Announce New Posts tag
$LastChangedDate: 2010-09-23 15:31:54 +0100 (Thu, 23 Sep 2010) $
$Rev: 4695 $
*/

if (preg_match('#' . basename(__FILE__) . '#', $_SERVER['PHP_SELF']))
{
	die('Access Denied');
}

sf_forum_ahah_support();
# --------------------------------------------

sf_new_post_announce_display();

die();

?>