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
define('AUTH_KEY',         '# KpQFg>)U-lo}m#9G{ZvR8#@.o2mub;khVv*_9kz?HTfrji.3$-@ixKIy(%|2E_');
define('SECURE_AUTH_KEY',  'CHDB*itJb1)F tB7cuCPWCs!HiWSW#8%S094mFU{Od/8nWpuU+8gx{B3x$V>YHro');
define('LOGGED_IN_KEY',    'W$za7SAUIn+BXI*y*ZBRwTAaQ1rDVkb=knbDF*>?1I29 v1MtPj^c7a&iNF|Z:C1');
define('NONCE_KEY',        '7iArq,K>NAf0s(}Tlw c:LR-cZW=6QJ8Z+qSP>bW&IY~[fbc0tNdixN z/v!)iA_');
define('AUTH_SALT',        'FHO9a:9p_!Cu=[(UcNO2u7Sb>E=Gxb>.rNj}M%YMj.wlqh5_NhrdH$mUYZ`Uld~g');
define('SECURE_AUTH_SALT', 'MR2xd!kdm]T,:fiia&OgIS{;AZ:%&GlJ^J@e8LXT}A %It&t%Motwy*0_GV{4_PZ');
define('LOGGED_IN_SALT',   'jJmBug^3Xh*u/t&Em!lFj><@sZrMPqD`aeL(~`dK91NCUVQAK|#u->,e|m3q*0(P');
define('NONCE_SALT',       'f~Ej*#~NwQaW+SC[hJ+44A.J9C4p 0y=wfH~[RAdW3rdLa>[4~nAz)@dj}MF#SzK');

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
