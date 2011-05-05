<?php
/**
 * The base configurations of the WordPress.
 *
 * This file has the following configurations: MySQL settings, Table Prefix,
 * Secret Keys, WordPress Language, and ABSPATH. You can find more information
 * by visiting {@link http://codex.wordpress.org/Editing_wp-config.php Editing
 * wp-config.php} Codex page. You can get the MySQL settings from your web host.
 *
 * This file is used by the wp-config.php creation script during the
 * installation. You don't have to use the web site, you can just copy this file
 * to "wp-config.php" and fill in the values.
 *
 * @package WordPress
 */

// ** MySQL settings - You can get this info from your web host ** //
/** The name of the database for WordPress */
define('DB_NAME', 'wordpress');

/** MySQL database username */
define('DB_USER', 'wordpress');

/** MySQL database password */
define('DB_PASSWORD', 'wp1');

/** MySQL hostname */
define('DB_HOST', 'localhost');

/** Database Charset to use in creating database tables. */
define('DB_CHARSET', 'utf8');

/** The Database Collate type. Don't change this if in doubt. */
define('DB_COLLATE', '');

/**#@+
 * Authentication Unique Keys and Salts.
 *
 * Change these to different unique phrases!
 * You can generate these using the {@link https://api.wordpress.org/secret-key/1.1/salt/ WordPress.org secret-key service}
 * You can change these at any point in time to invalidate all existing cookies. This will force all users to have to log in again.
 *
 * @since 2.6.0
 */
define('AUTH_KEY',         '2iWJ~A]5}~3wy~T)}`&?J&6N@D~FSVooa/s|=bIkP9Wjcj6$[|<.7>h]i$vr77p>');
define('SECURE_AUTH_KEY',  '~,T/?|:?g,+e>sJwt,[65ZNH.y4JL-N[uX6cwI_Q?@wlIgZ9#vZteo3NIXa2t^d(');
define('LOGGED_IN_KEY',    '&#Oy2VeWPg<HWHf_8hx.v+AbFEvNN~LItoaqUJ>Wsk+UX~b|[;aT~HH!jvv:w>pY');
define('NONCE_KEY',        '>]6O7Eq^LRVw0ba40#r^p_j!u`3baAd:0La-*OuC:@^0HqK0Xm{c*vL>$&j$XBSK');
define('AUTH_SALT',        '5_aGsdV^FfO.aHg8<4WV5P,tI(fHp=;y*s-wO~$|eD6C*]EY/4auEj>k4)!DvZdi');
define('SECURE_AUTH_SALT', 'R+;.Vi8A{:Jgp&b&Ne-]DQ^>L6}Md]m# *o8OH?&QCgx[CF.[zV<ZwJ~c.3f(f*x');
define('LOGGED_IN_SALT',   'jU=#4J#3jW`^s@kH}3.}ZG*7h|pqwd|?LXw/Hi`Q-HUY<++N{@=Sak%U)zQ4I^B|');
define('NONCE_SALT',       'RVV2i^TsMELo=c|}R)@d3kaU+PEfT0kaZp9ktJtQDE <}-l7Rcj@9OgdcTRwU`LE');

/**#@-*/

/**
 * WordPress Database Table prefix.
 *
 * You can have multiple installations in one database if you give each a unique
 * prefix. Only numbers, letters, and underscores please!
 */
$table_prefix  = 'wp_';

/**
 * WordPress Localized Language, defaults to English.
 *
 * Change this to localize WordPress. A corresponding MO file for the chosen
 * language must be installed to wp-content/languages. For example, install
 * de_DE.mo to wp-content/languages and set WPLANG to 'de_DE' to enable German
 * language support.
 */
define('WPLANG', '');

/**
 * For developers: WordPress debugging mode.
 *
 * Change this to true to enable the display of notices during development.
 * It is strongly recommended that plugin and theme developers use WP_DEBUG
 * in their development environments.
 */
define('WP_DEBUG', false);

/* That's all, stop editing! Happy blogging. */

/** Absolute path to the WordPress directory. */
if ( !defined('ABSPATH') )
	define('ABSPATH', dirname(__FILE__) . '/');

/** Sets up WordPress vars and included files. */
require_once(ABSPATH . 'wp-settings.php');
