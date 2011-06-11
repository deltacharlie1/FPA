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

wp_create_user($argv[1],$argv[2],$argv[3]);

?>
