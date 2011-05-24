// [include-html file="file.html"]
function include-html_func( $atts ) {
	extract( shortcode_atts( array(
		'file' => 'error.tt',
	), $atts ) );
	include('/usr/local/git/fpa/htdocs/lib/'.{$file});
	return "";
}
add_shortcode( 'include-html', 'include-html_func' );
