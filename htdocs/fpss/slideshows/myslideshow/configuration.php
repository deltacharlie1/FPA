<?php
/* ---------------------------------------------------------------------------------------------- */
/* ------------ Your configuration file for this Frontpage Slideshow 1.7.x instance. ------------ */
/* ---------------------------------------------------------------------------------------------- */

$fpsslanguage = "english"; // Set your slideshow language here. Frontpage Slideshow 1.7.2 ships with English and French only. Next versions will feature more languages.

// --- Slideshow presentation settings (tip: these are most frequently changed if you're using multiple slideshows in your site) --- //
$fpss_template = "Movies"; // Choose the output template of this slideshow: "Default", "FSD", "Movies", "JJ-Obs", "JJ-Rasper", "Movies", "Sleek", "TT", "Uncut". See them all live on: www.frontpageslideshow.net
$hide_nav = 0; // Hide navigation bar? 0 for "no", 1 for "yes". Default is 0. This option only affects templates that utilize some sort of "sidebar".
$width = 703; // Slideshow Width in pixels. Please note that this value references to the slide viewport. If you are using a template like Movies, whoich utilizes a sidebar, the total width of this slideshow will be the sum of this value and the sidebar width value (set below). Images exceeding this Width will display cropped without messing your slideshow.
$height = 150; // Slideshow Height in pixels. Please note that this value references to the slide viewport. Images exceeding this Height will display cropped without messing your slideshow.
$sidebar_width = 220; // Width of the Sidebar in pixels. Concerns the 'Uncut', 'FSD', 'Movies' and 'Sleek' templates by default. This width will be added to the slideshow Width set above.
$fpss_css_class = ""; // A CSS class to be applied to the container div of the slideshow, this allows individual slideshow styling using one CSS file. Empty by default.



// --- Slideshow engine settings --- //
$engine = "mootools"; // Choose Slideshow Engine, either "jquery" or "mootools". Default is jQuery. Choose appropriately to avoid any javascript conflicts with other extensions/plugins in your site (if using some CMS) or even your template! Wordpress and Drupal users should leave this option to jQuery.
$disablelib = 0; // Disable core javascript library inclusion? 0 for "no", 1 for "yes". Default is 0. If you are using other scripts on your site which already include either Mootools or jQuery, you might consider setting this option to '1', in case you are faced with javascript conflicts. This option will not work if you set the 'optimizejs' option below to '1'.
$optimizejs = 0; // Compress javascript code using PHP? 0 for "no", 1 for "yes". Default is 0. Improve your site's performance by enabling this feature. PHP compresses javascript code and minimizes page load times. This includes both the core javascript library and the slideshow engine. Please note that some servers may not support this feature.
$delay = 7000; // Set the Slide Delay (the pause between slides) in milliseconds. Default is "6000" (6 seconds).
$speed = 1000; // Set the Slideshow Speed (the transition time between slides) in milliseconds. Default is "1000" (1 second).
$mtCTRloadingTime = 500; // Preloader image (the animated logo image) delay time in milliseconds. Default is "500" (0.5 seconds).
$mtCTRrotateAction = "click"; // Choose how slides should switch when using the navigation. Values are "click" and "mouseover" for on click and on mouseover behaviour respectively.

// --- Extra settings only for the Mootools based slideshow engine --- //
$mtCTRtext_effect = 0; // Use text transition effect? 0 for "no", 1 for "yes". Default is 0. Adds a nice transition for text when switching between slides.
$mtCTRtransitionText = 1000; // Text transition effect time in milliseconds. Applies only if you've selected '1' to the above option. Default is "1000" (1 second).



// --- Slide content display settings (tip: control what content elements are displayed on your slideshow) --- //
$show_title = 0; // Display slide title?  0 for "no", 1 for "yes". Default is 1.
$show_category = 0;  // Display slide category?  0 for "no", 1 for "yes". Default is 1.
$show_tagline = 0; // Display slide tagline (teaser) text?  0 for "no", 1 for "yes". Default is 1. The tagline text is not utilized on all Frontpage Slideshow templates.
$show_slidetext = 0;  // Display slide text?  0 for "no", 1 for "yes". Default is 1. This is the main text for each slide.
$show_readmore = 0;  // Display "read more" button?  0 for "no", 1 for "yes". Default is 1.
$words = "26"; // Set a Word limit for the slide text. Default is "20" (20 words limit). Empty this option if you don't want to enforce a Word limit at all.
$chars = ""; // Set a Character limit for the slide text. Default is empty (no character limit). Leave empty if you don't want to enforce a Character limit at all. You should not use the Word and Character limits at the same time.
$striptags = 1; // Cleanup HTML tags from slide text? 0 for "no", 1 for "yes". Default is 1. If you choose '1' then all HTML tags will be stripped from the main text of your slide, except the tags specified in the mod_fpslideshow.php file. It's best if you leave this to 1.
$openlinksexternally = 0;
$random_ordering = 0; // Display slides randomly? 0 for "no", 1 for "yes". Default is 0. This option will shuffle the slides in your slideshow.
$limitslides = ""; // Limit the slides being displayed. This option can be very useful if you have for example 30 slides on your slideshow but only want to show 10 at a time. You input '10' in this case and only 10 slides will appear. If you combine this option with the 'random' feature right above, you'll get a smart display feature for your slideshow. By default this option is empty to enable display of all slides.



/* ------------ End of your configuration file for this Frontpage Slideshow instance. ------------ */

?>