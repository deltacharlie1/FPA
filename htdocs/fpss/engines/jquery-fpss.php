<?php 
/*
// "Frontpage Slideshow" by JoomlaWorks - Version 1.7.2
// Copyright (c) 2006 - 2008 JoomlaWorks, a Komrade LLC company.
// This code cannot be redistributed without permission from JoomlaWorks - http://www.joomlaworks.gr.
// More info at http://www.joomlaworks.gr and http://www.frontpageslideshow.net
// Developers: Fotis Evangelou - George Chouliaras
// ***Last update: May 4th, 2008***
*/
ob_start ("ob_gzhandler"); 
header("Content-type: text/javascript; charset: UTF-8"); 
header("Cache-Control: must-revalidate"); 
$offset = 60 * 60 ; 
$ExpStr = "Expires: " .  
gmdate("D, d M Y H:i:s", 
time() + $offset) . " GMT"; 
header($ExpStr);
include("jquery-comp.js");
echo "\n\n";
include("jquery-fpss-comp.js");
ob_flush();

?>