<?php
/*
Plugin Name: Include HTML 
Plugin URI: http://example.com/magic-plugin
Description: Magic Plugin performs magic
Version: 1.0
Author: Doug Conran
Author URI: http://example.com/
*/
// [include-html file="file.html"]

function include_html_func( $atts ) {
	return file_get_contents('/usr/local/git/fpa/htdocs/lib/'.$atts['file']);
}
add_shortcode( 'include-html', 'include_html_func' );
?>
