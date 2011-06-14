<?php
/**
 * WordPress User Page
 *
 * Handles authentication, registering, resetting passwords, forgot password,
 * and other user handling.
 *
 * @package WordPress
 */

/** Make sure that the WordPress bootstrap has run before continuing. */
/** require( dirname(__FILE__) . '/wp-load.php' ); 
*/

require( '/usr/local/git/fpa/htdocs/wp-load.php' );
query_posts($query_string . '&posts_per_page=3');
if ( have_posts() ) : while ( have_posts() ) : the_post();
print <<<EOD
<li>
<h4><a href=
EOD;
the_permalink();
echo ">";
the_title();

the_date();

echo "</a></h4>";

the_excerpt();
echo "</li>";

endwhile; else:
echo "Sorry, no posts matched your criteria.";
endif;

?>
