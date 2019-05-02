<?php
/**
 * The base configuration for WordPress
 *
 * The wp-config.php creation script uses this file during the
 * installation. You don't have to use the web site, you can
 * copy this file to "wp-config.php" and fill in the values.
 *
 * This file contains the following configurations:
 *
 * * MySQL settings
 * * Secret keys
 * * Database table prefix
 * * ABSPATH
 *
 * @link https://codex.wordpress.org/Editing_wp-config.php
 *
 * @package WordPress
 */

// ** MySQL settings ** //
/** The name of the database for WordPress */
define( 'DB_NAME', 'wordpress' );

/** MySQL database username */
define( 'DB_USER', 'root' );

/** MySQL database password */
define( 'DB_PASSWORD', 'my-secret-pw' );

/** MySQL hostname */
define( 'DB_HOST', 'mysql' );

/** Database Charset to use in creating database tables. */
define( 'DB_CHARSET', 'utf8' );

/** The Database Collate type. Don't change this if in doubt. */
define( 'DB_COLLATE', '' );

/**
 * Authentication Unique Keys and Salts.
 *
 * Change these to different unique phrases!
 * You can generate these using the {@link https://api.wordpress.org/secret-key/1.1/salt/ WordPress.org secret-key service}
 * You can change these at any point in time to invalidate all existing cookies. This will force all users to have to log in again.
 *
 * @since 2.6.0
 */
define( 'AUTH_KEY',          '__{sT[m^up%hAfwX}F;4U3y%_.-s,&%6UW._T5>rw2ZG-/5@(zyn~moob-K96Ak<' );
define( 'SECURE_AUTH_KEY',   'jg7f%wZ#_=ji+#)(pIF:759q_Ku5G=bZF?d]jeLuu;)Z5+wTnn.h]Qtnth){x@%H' );
define( 'LOGGED_IN_KEY',     'y9R|.3)wWSAb&Xsd96:MSLcl&O=[Xyc&*auPhc#jOPeJM2|rG# @T##eIBobsBl%' );
define( 'NONCE_KEY',         'xE!fE%W:ZCsYS}lV1ap=9@5-C#{vUUl*YUgw/0L)zt#^F,.=/-)g8^vDhP/0< U}' );
define( 'AUTH_SALT',         '6;&l=U{yK1)X![]1IcH!s)PE+itQmqm^ZT6hxC!&^C]l&+{5XL1LkaNE#XFLrQna' );
define( 'SECURE_AUTH_SALT',  ')2ji?K4TXQN~r^Ca_{2Kv0WeTfOTNj4G%x_8pSY(4u{. g$sm7z?h&Ih=6&r-2DU' );
define( 'LOGGED_IN_SALT',    'gh[3,ZGnW^s`)U|%^]hq8mq%K~,?9qTWgY <<#4LwFocXX K(.L@Ri5|{H,Phy#u' );
define( 'NONCE_SALT',        'O~UBoj!Cdeb_Yg+HysPvfv*D(V0wSpG>i!(PVhL{rzBeV*HojTN6/];D045N<X5[' );
define( 'WP_CACHE_KEY_SALT', '9%4~Gago?(^V{Y29e.(+g@`tdL!6)x:eb>ykh]q5ZYoUzPb5Kpl}IRyjq2y^j|K8' );

/**
 * WordPress Database Table prefix.
 *
 * You can have multiple installations in one database if you give each
 * a unique prefix. Only numbers, letters, and underscores please!
 */
$table_prefix = 'wp_';




/* That's all, stop editing! Happy blogging. */

/** Absolute path to the WordPress directory. */
if ( ! defined( 'ABSPATH' ) )
	define( 'ABSPATH', dirname( __FILE__ ) . '/' );

/** Sets up WordPress vars and included files. */
require_once ABSPATH . 'wp-settings.php';
