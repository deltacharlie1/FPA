<?php
/*
// "Frontpage Slideshow" by JoomlaWorks - Version 1.7.2
// Copyright (c) 2006 - 2008 JoomlaWorks, a Komrade LLC company.
// This code cannot be redistributed without permission from JoomlaWorks - http://www.joomlaworks.gr.
// More info at http://www.joomlaworks.gr and http://www.frontpageslideshow.net
// Developers: Fotis Evangelou - George Chouliaras
// ***Last update: May 4th, 2008***
*/

require_once($AbsoluteServerPathofyoursite.'/fpss/slideshows/'.$nameOfSlideshowToDisplay.'/configuration.php');
require_once($AbsoluteServerPathofyoursite.'/fpss/slideshows/'.$nameOfSlideshowToDisplay.'/data.php');
require_once($AbsoluteServerPathofyoursite.'/fpss/language/'.$fpsslanguage.'.php');

// Folder settings
$slideimagefolder = $URLofyoursite.'/fpss/slideshows/'.$nameOfSlideshowToDisplay.'/images/';
$enginefolder = $URLofyoursite."/fpss/engines/";
$templatefolder = $URLofyoursite."/fpss/templates/";



// ---------------------------------- TEXT PROCESSING ---------------------------------- //

// Group Navigation
if ($fpss_template=='JJ-Obs' || $fpss_template=='JJ-Rasper') { $groupnav = 1; } else { $groupnav = 0; }

// Hide .fpss-introtext completely if the content is hidden as well
if (!$show_title && !$show_category && !$show_slidetext && !$show_tagline && !$show_readmore) {
	$hidecontent = ' style="display:none;"';
} else {
	$hidecontent = '';
}
if($striptags){
	$allowed_tags = "<a><b><span>"; // these tags will NOT be stripped off!
}
if($openlinksexternally){$target = ' target="_blank"';}
if ($mtCTRtext_effect) {$mtCTRtext_effect == 'true';} else {$mtCTRtext_effect == 'false';}

// CRD
$crd = base64_decode("PGRpdiBzdHlsZT0iZGlzcGxheTpub25lOyI+PGEgaHJlZj0iaHR0cDovL3d3dy5qb29tbGF3b3Jr
cy5nciI+RnJvbnRwYWdlIFNsaWRlc2hvdyAodmVyc2lvbiAxLjcuMikgLSBDb3B5cmlnaHQgJmNv
cHk7IDIwMDYtMjAwOCBieSBKb29tbGFXb3JrczwvYT48L2Rpdj4=");
	
if($random_ordering) {shuffle($slides);}

// ---------------------------------- SLIDE OUTPUT ---------------------------------- //

$html = '';

// Start loop
$step = 1;
if($limitslides) {$i = 0;}

foreach ($slides as $slide) {

	// Limit
	if($limitslides) { if($i>=$limitslides) continue; }
	
	// Slide data
	$slidelink = $slide['slidelink'];
	$slidetitle = $slide['title'];
	$slidecategory = $slide['category'];
	$slidetagline = $slide['tagline'];
	$slidetext = preg_replace("/<img.+?>/", "", $slide['text']);
	$slideimage = $slideimagefolder.$slide['slideimage'];
	
	// Assemble slide content
	
	$slidecontent = "\n";
	// ---Title---
	if ($show_title) {
		$slidecontent .= "<h1><a".$target." href=\"".$slidelink."\">".$slidetitle."</a></h1>\n";
	}
	
	// ---Category (if applicable)---
	if ($show_category) {
		$slidecontent .= "<h2>".$slidecategory."</h2>\n";
	}

	// ---Tagline text---
	if ($show_tagline) {
		$slidecontent .= "<h3>".strip_tags($slidetagline)."</h3>\n";
	}
	
	// ---Slide text---
	// HTML cleanup
	if ($striptags) {
		$slidetext = strip_tags($slidetext, $allowed_tags);
	}
	// Character limit
	if ($chars) { 
		if(function_exists("mb_string")) {
			$slidetext = mb_substr($slidetext, 0, $chars).'...'; 
			} else {
			$slidetext = substr($slidetext, 0, $chars).'...';
		}
	}	 
	// Word limit
	if (!function_exists('word_limiter')) {
		function word_limiter($str, $limit = 100, $end_char = '&#8230;') {
			  if (trim($str) == '')
			  return $str;
			  preg_match('/\s*(?:\S*\s*){'. (int) $limit .'}/', $str, $matches);
			  if (strlen($matches[0]) == strlen($str)) $end_char = '';
			  return rtrim($matches[0]).$end_char;
		}
	}
	if ($words) {
		$slidetext = word_limiter($slidetext,$words);
	}	
	if ($show_slidetext) {
		$slidecontent .= "<p>".$slidetext."</p>\n";
	}
	
	// ---The 'read more' link---
	if ($show_readmore) {
		$slidecontent .= "<a".$target." href=\"".$slidelink."\" class=\"readon\">"._MORE."</a>\n";
	}
	
	// Output
	$html .= '
	<div class="slide">
		<div class="slide-inner">
			<a'.$target.' class="fpss_img" href="'.$slidelink.'">
				<span>
					<span style="background:url('.$slideimage.') no-repeat;">
						<span>
							<img src="'.$slideimage.'" alt="'._FPSS_MOD_IMGALT.'" />
						</span>
					</span>
				</span>
			</a>
			<div class="fpss-introtext"'.$hidecontent.'>
				<div class="slidetext">'.$slidecontent.'</div>
			</div>
		</div>
	</div>
	';
	
	if($limitslides) {$i++;}
	$step++;
}	



// ---------------------------------- NAVIGATION OUTPUT ---------------------------------- //

$navhtml = '';				
$step = 1;
if($limitslides) {$j = 0;}
foreach ($slides as $key => $slide) {
	if($limitslides) {if($j>=$limitslides) continue;}

	// Slide data
	$slidelink = $slide['slidelink'];
	$slidetitle = $slide['title'];
	$slidetagline = strip_tags($slide['tagline']);
	$slideimage = $slideimagefolder.$slide['slideimage'];

	$key = $key + 1;
	if ($key < 10) { $key = "0".$key; }
	$navhtml .= '
	<li>
		<a class="navbutton off navi" href="javascript:void(0);" title="'._FPSS_MOD_CLICKNAV.'"';
	if ($mtCTRrotateAction=='mouseover') {$navhtml .= ' onclick="parent.location=\''.$slidelink.'\';return false;"';}	
	$navhtml .= '>
			<span class="navbar-img"><img src="'.$slideimage.'" alt="'._FPSS_MOD_CLICKNAV.'" /></span>
			<span class="navbar-key">'.$key.'</span>
			<span class="navbar-title">'.$slidetitle.'</span>
			<span class="navbar-tagline">'.$slidetagline.'</span>
			<span class="navbar-clr"></span>
		</a>
	</li>
	';
	if($limitslides) {$j++;}
	$step++;
}

?>

<!-- JoomlaWorks "Frontpage Slideshow" v1.7.2 starts here -->
<script language="javascript" type="text/javascript">
<!--
var embedFPSSCSS = '<' + 'style type="text/css" media="all">'
+ '@import "<?php echo $templatefolder.$fpss_template; ?>/template_css.php?w=<?php echo $width; ?>&h=<?php echo $height; ?>&sw=<?php echo $sidebar_width;?>";'
<?php if ($hide_nav) {$sidebar_width = 0; echo "+ '#navi-outer {display:none;}'"; } ?>
+ '</' + 'style>';
document.write(embedFPSSCSS);
-->
</script>
<?php if (!$hide_nav) { ?>
<!--[if lte IE 7]>
<style type="text/css" media="all">
@import "<?php echo $templatefolder.$fpss_template; ?>/template_css_ie.css";
</style>
<![endif]-->
<?php } ?>
<?php if($optimizejs) {?>
<script language="javascript" type="text/javascript" src="<?php echo $enginefolder.$engine; ?>-fpss.php"></script>
<?php } else { ?>
<?php if(!$disablelib) {?>
<script language="javascript" type="text/javascript" src="<?php echo $enginefolder.$engine; ?>-comp.js"></script>
<?php } ?>
<script language="javascript" type="text/javascript" src="<?php echo $enginefolder.$engine; ?>-fpss-comp.js"></script>
<?php } ?>
<script language="javascript" type="text/javascript">
<?php if ($engine=='jquery') { ?>
var speed_delay = <?php echo $delay; ?>;
var slide_speed = <?php echo $speed; ?>;
var CTRrotateAction = '<?php echo $mtCTRrotateAction; ?>';
<?php } ?>
<?php if ($engine=='mootools') { ?>
var CTRloadingTime = <?php echo $mtCTRloadingTime; ?>;
var CTRslideInterval = <?php echo $delay; ?>;
var CTRtransitionDuration = <?php echo $speed; ?>;
var CTRtransitionText = <?php echo $mtCTRtransitionText; ?>;
var CTRrotateAction = '<?php echo $mtCTRrotateAction; ?>';
var CTRtext_effect = <?php echo $mtCTRtext_effect; ?>;
<?php } ?>
</script>

<div id="fpss-outer-container"<?php if ($fpss_css_class) {echo ' class="'.$fpss_css_class.'"';} ?>>
    <div id="fpss-container">
        <div id="fpss-slider">
            <div id="slide-loading"></div>
            <div id="slide-wrapper">
                <div id="slide-outer"><?php echo $html; ?></div>
            </div>
        </div>
        <div id="navi-outer">
            <div id="pseudobox"></div>
            <div class="ul_container">
                <ul>		
			<?php if ($groupnav) { ?>
                <?php echo $navhtml; ?>
                <li class="noimages"><a id="fpss-container_next" href="javascript:void(0);" onclick="showNext();clearSlide();" title="<?php echo _FPSS_MOD_NEXT; ?>"></a></li>
                <li class="noimages"><a id="fpss-container_playButton" href="javascript:void(0);" onclick="playButtonClicked();return false;" title="<?php echo _FPSS_MOD_PLAYPAUSE; ?>"><?php echo _FPSS_MOD_PAUSE; ?></a>
                <li class="noimages"><a id="fpss-container_prev" href="javascript:void(0);" onclick="showPrev();clearSlide();" title="<?php echo _FPSS_MOD_PREV; ?>"></a></li>
                <li class="clr"></li>
            <?php } else { ?>
                <li class="noimages"><a id="fpss-container_prev" href="javascript:void(0);" onclick="showPrev();clearSlide();" title="<?php echo _FPSS_MOD_PREV; ?>">&laquo;</a></li>
                <?php echo $navhtml; ?>
                <li class="noimages"><a id="fpss-container_next" href="javascript:void(0);" onclick="showNext();clearSlide();" title="<?php echo _FPSS_MOD_NEXT; ?>">&raquo;</a></li>
                <li class="noimages"><a id="fpss-container_playButton" href="javascript:void(0);" onclick="playButtonClicked();return false;" title="<?php echo _FPSS_MOD_PLAYPAUSE; ?>"><?php echo _FPSS_MOD_PAUSE; ?></a></li>
            <?php } ?>
                </ul>
            </div>
        </div> 
    	<div class="fpss-clr"></div>
    </div>
	<div class="fpss-clr"></div> 
</div>
<?php echo $crd; ?>
<!-- JoomlaWorks "Frontpage Slideshow" v1.7.2 ends here -->
