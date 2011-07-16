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
define('AUTH_KEY',         'voIW9nl{9+YmbuKEWhfNQ1KIo:8K(R]HQB_Vd%g8}J%p$`ob`&D~y=D(eJQ?l(h/');
define('SECURE_AUTH_KEY',  '+M~B1lxP3Ox#pBp}&F[Nje8qp_[GZBlsYVrXYA1WVAmCIt7=#[m_&a9Bs:THrh@g');
define('LOGGED_IN_KEY',    'HB67boCW)-gxD|e~$87J;_Jy!jxb^oWX@eN%:X.sH-}$XS}7(C6ZwQ:71,$e|;*W');
define('NONCE_KEY',        '^jhuO-O^jyt(Db<d=_/E%3RaHG84pJ?[+|.2WIy!U^QMg+EK0x [lkyv/Omj<Lz.');
define('AUTH_SALT',        'K%OQ[lB!^~QZUHp*zx3j><>1_6y^|v7SCX/R<X-ki&Od:VQxI*jL18j5iL(sVTv:');
define('SECURE_AUTH_SALT', 'U`maI Eh3!EnfS_5{c&j`}PE`9:f9g3KJBh.Ul}Ud/PY2{En~u?/I98gn;qTeoY>');
define('LOGGED_IN_SALT',   '=reY({UDX4XjTxo)x~Sc?jI+#>2DQ}|1H[;oeLRm^7i/q#UjkmUPJ+fYu_VYcF#|');
define('NONCE_SALT',       '9lFIi}9>NU3+{F?f)E ~m.H[|ji4=uzTQ6u=vQ0 Sn{zS,B8+$^o@wnn^wzbYNSP');

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
