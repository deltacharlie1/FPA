<?php

	add_editor_style();

	add_theme_support( 'post-thumbnails' );

	add_theme_support( 'automatic-feed-links' );

	register_nav_menus( array(
		'primary' => __( 'Primary Navigation', 'twentyten' ),
		'footer' => __( 'Footer Navigation', 'twentyten' ),
	) );

set_post_thumbnail_size( HEADER_IMAGE_WIDTH, HEADER_IMAGE_HEIGHT, true );

function twentyten_widgets_init() {

	register_sidebar( array(
		'name' => __( 'Home Quotes', 'twentyten' ),
		'id' => 'home-quotes',
		'description' => __( '', 'twentyten' ),
		'before_widget' => '<div class="panel"><div class="panel-wrapper">',
		'after_widget' => '</div></div>',
		'before_title' => '',
		'after_title' => '',
	) );

	register_sidebar( array(
		'name' => __( 'Home Sidebar', 'twentyten' ),
		'id' => 'home-side',
		'description' => __( '', 'twentyten' ),
		'before_widget' => '',
		'after_widget' => '</ul>',
		'before_title' => '<img alt="Free, Easy, Secure" class="break" src="',
		'after_title' => '" /><ul>',
	) );

	register_sidebar( array(
		'name' => __( 'News Sidebar', 'twentyten' ),
		'id' => 'news-side',
		'description' => __( '', 'twentyten' ),
		'before_widget' => '<li>',
		'after_widget' => '</li>',
		'before_title' => '<h3>',
		'after_title' => '</h3>',
	) );

	register_sidebar( array(
		'name' => __( 'Green Bar Option 1', 'twentyten' ),
		'id' => 'option-one',
		'description' => __( '', 'twentyten' ),
		'before_widget' => '<div class="textwidget">',
		'after_widget' => '</div>',
		'before_title' => '<h3>',
		'after_title' => '</h3>',
	) );

	register_sidebar( array(
		'name' => __( 'Green Bar Option 2', 'twentyten' ),
		'id' => 'option-two',
		'description' => __( '', 'twentyten' ),
		'before_widget' => '<div class="textwidget">',
		'after_widget' => '</div>',
		'before_title' => '<h3>',
		'after_title' => '</h3>',
	) );

}
add_action( 'widgets_init', 'twentyten_widgets_init' );



function new_excerpt_length($length) {
	return 20;
}
add_filter('excerpt_length', 'new_excerpt_length');

function new_excerpt_more($more) {
	return '';
}
add_filter('excerpt_more', 'new_excerpt_more');

//remove_action( 'wp_head',             'wp_enqueue_scripts',            1     );
remove_action( 'wp_head',             'feed_links',                    2     );
remove_action( 'wp_head',             'feed_links_extra',              3     );
remove_action( 'wp_head',             'rsd_link'                             );
remove_action( 'wp_head',             'wlwmanifest_link'                     );
remove_action( 'wp_head',             'index_rel_link'                       );
remove_action( 'wp_head',             'parent_post_rel_link',          10, 0 );
remove_action( 'wp_head',             'start_post_rel_link',           10, 0 );
remove_action( 'wp_head',             'adjacent_posts_rel_link_wp_head', 10, 0 );
remove_action( 'wp_head',             'locale_stylesheet'                    );
remove_action( 'publish_future_post', 'check_and_publish_future_post', 10, 1 );
//remove_action( 'wp_head',             'noindex',                       1     );
remove_action( 'wp_head',             'wp_print_styles',               8     );
//remove_action( 'wp_head',             'wp_print_head_scripts',         9     );
remove_action( 'wp_head',             'wp_generator'                         );
//remove_action( 'wp_head',             'rel_canonical'                        );
remove_action( 'wp_footer',           'wp_print_footer_scripts'              );
remove_action( 'wp_head',             'wp_shortlink_wp_head',          10, 0 );
remove_action( 'template_redirect',   'wp_shortlink_header',           11, 0 );

add_action('widgets_init', 'my_remove_recent_comments_style');
function my_remove_recent_comments_style() {
    global $wp_widget_factory;
    remove_action('wp_head', array($wp_widget_factory->widgets['WP_Widget_Recent_Comments'], 'recent_comments_style'));
}
