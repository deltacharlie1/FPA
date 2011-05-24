<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" <?php language_attributes(); ?>>

<head profile="http://gmpg.org/xfn/11">
<meta http-equiv="Content-Type" content="<?php bloginfo('html_type'); ?>; charset=<?php bloginfo('charset'); ?>" />

<title><?php wp_title(''); ?><?php if(wp_title('', false)) { echo ' |'; } ?> <?php bloginfo('name'); ?></title>
<link rel="stylesheet" href="<?php bloginfo('stylesheet_directory'); ?>/css/screen.css" type="text/css" media="screen, projection" />
<link rel="stylesheet" href="<?php bloginfo('stylesheet_directory'); ?>/css/print.css" type="text/css" media="print" />
<!--[if IE]><link rel="stylesheet" href="<?php bloginfo('stylesheet_directory'); ?>/css/ie.css" type="text/css" media="screen, projection"><![endif]-->
<!--[if IE 6]>
	<script src="<?php bloginfo('template_url'); ?>/js/pngfix.js"></script>
<![endif]--> 
<link rel="stylesheet" href="<?php bloginfo('stylesheet_url'); ?>" type="text/css" media="screen" />
<link rel="alternate" type="application/rss+xml" title="<?php bloginfo('name'); ?> RSS Feed" href="<?php bloginfo('rss2_url'); ?>" />
<link rel="alternate" type="application/atom+xml" title="<?php bloginfo('name'); ?> Atom Feed" href="<?php bloginfo('atom_url'); ?>" />
<link rel="pingback" href="<?php bloginfo('pingback_url'); ?>" />
<?php if(get_theme_option('favicon') != '') { ?>
<link rel="shortcut icon" href="<?php echo get_theme_option('favicon'); ?>" type="image/x-icon" />
<?php } ?>

<?php wp_head(); ?>
<?php echo get_theme_option("head") . "\n"; ?>
</head>
<body>
	<div id="wrapper">
		<div id="container" class="container">  
            <?php $sidebar_over_header = get_theme_option('sidebar_over_header') == 'true' ? true : false; ?>
            
			<div class="<?php if($sidebar_over_header) { echo 'span-16';} else { echo 'span-24';} ?>">
                <div id="header">
                    <?php
					$get_logo_image = get_theme_option('logo');
					if($get_logo_image != '') {
						?>
						<a href="<?php bloginfo('url'); ?>"><img src="<?php echo $get_logo_image; ?>" alt="<?php bloginfo('name'); ?>" title="<?php bloginfo('name'); ?>" class="logo" /></a>
						<?php
					} else {
						?>
						<h1><a href="<?php bloginfo('url'); ?>"><?php bloginfo('name'); ?></a></h1>
						<h2><?php bloginfo('description'); ?></h2>
						<?php
					}
					?>
				</div>
                
                <div class="navcontainer">
					<ul id="nav">
						<li <?php if(is_home()) { ?> class="current_page_item" <?php } ?>><a href="<?php echo get_option('home'); ?>/">Home</a></li>
						<?php wp_list_pages('depth=1&number=6&sort_column=menu_order&title_li=' ); ?>		
					</ul>
				</div>
            <?php if(!$sidebar_over_header) { ?></div><div class="span-16"><?php } ?>