/*
// "Frontpage Slideshow" by JoomlaWorks - Version 1.7.2
// Copyright (c) 2006 - 2008 JoomlaWorks, a Komrade LLC company.
// This code cannot be redistributed without permission from JoomlaWorks - http://www.joomlaworks.gr.
// More info at http://www.joomlaworks.gr and http://www.frontpageslideshow.net
// Developers: Fotis Evangelou - George Chouliaras
// ***Last update: May 4th, 2008***
*/

-------------------------------------------------------------
QUICK INSTALLATION
-------------------------------------------------------------

1. Unpack the Static PHP version zip file.

2. Navigate inside the folder "fpss" to "slideshows", copy the folder "demoslideshow" (inside the same directory) and rename the copy to "myslideshow". This will act as the folder of your slideshow.

3. Important: You need to maintain the structure of the slideshow folders. That means you ALWAYS put your slide images inside the "images" folder. Your slide contents are located inside the data.php file and the configuration options of your slideshow are located in the configuration.php file. The structure of your slideshow folder must always be:

fpss
  |__ slideshows
			|_yourslideshowfolder
							|_images
							|_configuration.php
							|_data.php

You can obviously change only the "yourslideshowfolder" to whatever you want.

4. Upload (using FTP) the entire "fpss" folder to the root of your site. If your site is www.mysite.com then you should be able to read this text on www.mysite.com/fpss/readme.txt

5. Find the page where you want to add the slideshow. Let's say this page is the index.php located at the root of your site as well. The code that you will use to call your slideshow is this:

<?php
// START of "Frontpage Slideshow" settings
	$nameOfSlideshowToDisplay = "myslideshow"; 					// Enter the name of your slideshow. Slideshows are in folders inside /fpss/slideshows/.
	$URLofyoursite = "http://www.mysite.com"; 					// Enter your site's URL.
	$AbsoluteServerPathofyoursite = "/home/user/public_html";	// Enter the root path of your site on the server.
	
	// do not edit below this line
	include_once($AbsoluteServerPathofyoursite."/fpss/mod_fpslideshow.php");
// END of "Frontpage Slideshow" settings
?>

Edit the code block to reflect your site's paths.
You may want to check out the supplied demoslideshow.php file that comes with the zip file you unpacked and see how the code is applied.

6. Open your browser and go to www.mysite.com/index.php. You will see the demo slideshow in place as we haven't yet edited our slideshow. This is what we'll do next.

4. First change the CONFIGURATION options of your slideshow. Locate the configuration.php file inside /fpss/slideshows/myslideshow/ and edit it per your needs. Make sure you read carefully what each option does.

5. Add your SLIDES: Edit your slideshow's data.php file (in the same folder) to add/delete slides. Simply copy/paste or delete the data blocks marked with "slide elements" and edit the properties of each block to reflect each slide's contents (slide title, category, tagline, text, image). The demo slideshow has 4 slides in it but you can add as many as you want.

6. When you're done with editing the contents and configuration options of your slideshow, re-open your browser and again navigate to www.mysite.com/index.php. Et voila! Enjoy your Frontpage Slideshow!



-------------------------------------------------------------
INSTRUCTIONS FOR WORDPRESS, DRUPAL and other CMS users...
-------------------------------------------------------------

When using a CMS like Wordpress or Drupal (or any other PHP based CMS), the steps to add Frontpage Slideshow in your template/theme are exactly the same as the above.

- For Drupal users add the FPSS code block inside the page.tpl.php file of your theme, located in themes/yourtheme/

- For Wordpress users add the FPSS code block inside the index.php file of your theme, located in wp-content/themes/yourtheme/

In a similar manner you can add Frontpage Slideshow on other popular CMSs like Textpattern, e107, CMS Made Simple, XOOPS, Magento (e-commerce), Zen Cart (e-commerce), osCommerce (e-commerce), Simple Machines Forum (SMF) (forum), phpBB (forum) and many more.



////////////////////////////////////////////////////////
Last edited: May 4th, 2008
Author: Fotis Evangelou - www.joomlaworks.gr
////////////////////////////////////////////////////////
