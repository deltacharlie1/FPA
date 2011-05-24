<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en" xml:lang="en">
<head>

<title><?php
	/*
	 * Print the <title> tag based on what is being viewed.
	 */
	global $page, $paged;

	wp_title( '|', true, 'right' );

	// Add the blog name.
	bloginfo( 'name' );

	// Add the blog description for the home/front page.
	$site_description = get_bloginfo( 'description', 'display' );
	if ( $site_description && ( is_home() || is_front_page() ) )
		echo " | $site_description";

	// Add a page number if necessary:
	if ( $paged >= 2 || $page >= 2 )
		echo ' | ' . sprintf( __( 'Page %s', 'twentyten' ), max( $paged, $page ) );

	?></title>
    
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />

<link rel="pingback" href="<?php bloginfo( 'pingback_url' ); ?>" />

<link rel="stylesheet" type="text/css" href="<?php bloginfo('template_directory'); ?>/style.css"/>
<link rel="stylesheet" type="text/css" href="<?php bloginfo('template_directory'); ?>/js/coda/coda-slider-2.0.css"/>

<?php wp_head(); ?>

<script src="<?php bloginfo('template_directory'); ?>/js/coda/jquery.easing.1.3.js" type="text/javascript"></script>
<script src="<?php bloginfo('template_directory'); ?>/js/coda/jquery.coda-slider-2.0.js" type="text/javascript"></script>
<?php if (is_page('faqs')) { ?>
<script type="text/javascript" src="/js/jquery-faqs.js"></script>
<link rel="stylesheet" type="text/css" href="/faqs.css"/>
<?php } ?>

<script type="text/javascript">
	$().ready(function() {
		$('#testimionials').codaSlider({
				dynamicArrows: false,
				dynamicTabs: true,
				dynamicTabsPosition: "bottom",
				autoSlide: true,
				autoSlideInterval: 5000,
				autoSlideStopWhenClicked: false
		});
	});
</script>


</head>

<body>

    <div class="top-green"></div>
        
        <div class="m header">
        
            <a href="<?php echo get_site_url(); ?>" class="logo" title="Free Plus Accounts"><img src="<?php bloginfo('template_directory'); ?>/images/logo.jpg" alt="Free Plus Accounts" /></a>
            
          <div class="account listfix">
            
                <ul>
                    <li><a href="https://www.freeplusaccounts.co.uk/cgi-bin/fpa/register.pl" class="register"></a></li>
                    <li><a href="https://www.freeplusaccounts.co.uk/cgi-bin/fpa/login.pl" class="login"></a></li>
                </ul>
            
            </div>
            
          <div class="listfix" id="nav">
                
				<?php wp_nav_menu( array( 'container_class' => 'menu-header', 'theme_location' => 'primary' ) ); ?>
                        
            </div>
            
            <div class="clear"></div>
                    
    </div>
