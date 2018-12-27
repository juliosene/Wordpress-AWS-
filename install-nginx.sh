#!/bin/bash
# This script will install Nginx + PHP 7.2

# Script arguments
for var in "$@"
do
    if [[ $var = "varnish" ]]
    then
       InstallVarnish="yes"
    fi
    if [[ $var = "mariadb" ]]
    then
       InstallMariaDB="yes"
    fi
    if [[ $var = "wordpress" ]]
    then
       InstallWordpress="yes"
    fi
    if [[ $var = "w3tc" ]]
    then
       InstallW3TC="yes"
    fi
done

MyPassword=`date +%s | sha256sum | base64 | head -c 32`

cd ~
# sudo -i
sudo apt-get install language-pack-UTF-8
sudo locale-gen UTF-8
# sudo locale-gen "en_US.UTF-8"

apt-get install -fy python-software-properties
LC_ALL=en_US.UTF-8 add-apt-repository ppa:ondrej/php -y

sudo apt-get update && sudo apt-get -fy upgrade

# sudo locale-gen "en_US.UTF-8"
apt-get install -fy lsb-release bc
REL=`lsb_release -sc`
DISTRO=`lsb_release -is | tr [:upper:] [:lower:]`
NCORES=` cat /proc/cpuinfo | grep cores | wc -l`
WORKER=`bc -l <<< "4*$NCORES"`

# AppToInstall=${2:-"none"}
# wordpres, joomla, drupal

# Install NGinx from oficial repository

wget http://nginx.org/keys/nginx_signing.key
apt-key add nginx_signing.key
add-apt-repository "deb http://nginx.org/packages/$DISTRO $REL nginx"
# add-apt-repository "deb-src http://nginx.org/packages/$DISTRO $REL nginx"

apt-get install -fy python-software-properties
LC_ALL=en_US.UTF-8 add-apt-repository ppa:ondrej/php -y

if [[ $DISTRO = "debian" ]]
then
wget -q https://packages.sury.org/php/apt.gpg -O- | sudo apt-key add -
echo "deb https://packages.sury.org/php/ $REL main" | sudo tee /etc/apt/sources.list.d/php.list

apt-get install ca-certificates apt-transport-https
fi

apt-get -y update

# Install nfs common to mount shared filesystem
apt-get -y install nfs-common
# mount -t nfs4 -o krb5p availability-zone.file-system-id.efs.aws-region.amazonaws.com:/ /usr/share/nginx/html/webshare/ 
# by IP
# mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 mount-target-IP:/ /usr/share/nginx/html/webshare/

# apt-get install -y -f cifs-utils

# Remove Apache2 before install NginX
# apt-get remove -fy apache2

#Install NginX
apt-get install -fy nginx

# # PHP 7.2
apt-get install -fy php7.2
apt-get remove -yf apache2
apt-get install -fy php7.2-fpm php7.2-mysql php7.2-curl php7.2-gd php7.2-mbstring php7.2-zip php7.2-mysql php7.2-xml php7.2-imagick
# apt-get install -fy php-pear php7.2-fpm php7.2-mysql php7.2-curl php7.2-dev php7.2-gd php7.2-mbstring php7.2-zip php7.2-mysql php7.2-xml
# Memcache client installation
apt-get install -fy php7.2-memcached php7.2-redis

# TO INSTALL A FASTER REDIS CACHE PHP INTERFACE
# apt-get install -fy unzip
# apt-get install -fy php7.2-dev
# cd /tmp
# wget https://github.com/phpredis/phpredis/archive/master.zip -O phpredis.zip
# unzip -o /tmp/phpredis.zip && mv /tmp/phpredis-* /tmp/phpredis && cd /tmp/phpredis && phpize && ./configure && make && sudo make install
# sudo touch /etc/php/7.2/mods-available/redis.ini && echo extension=redis.so > /etc/php/7.2/mods-available/redis.ini
# sudo ln -s /etc/php/7.2/mods-available/redis.ini /etc/php/7.2/apache2/conf.d/redis.ini
# sudo ln -s /etc/php/7.2/mods-available/redis.ini /etc/php/7.2/fpm/conf.d/redis.ini
# sudo ln -s /etc/php/7.2/mods-available/redis.ini /etc/php/7.2/cli/conf.d/redis.ini


apt-get --purge autoremove -y
# replace www-data to nginx into /etc/php/7.0/fpm/pool.d/www.conf
#sed -i 's/www-data/nginx/g;'
sed -i 's/\;request_terminate_timeout = 0/request_terminate_timeout = 300/g;' /etc/php/7.2/fpm/pool.d/www.conf

sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 100M/g;s/post_max_size = 8M/post_max_size = 64M/g;s/max_execution_time = 30/max_execution_time = 300/g" /etc/php/7.2/fpm/php.ini

service php7.2-fpm restart

# backup default Nginx configuration
mkdir /etc/nginx/conf-bkp
cp /etc/nginx/conf.d/default.conf /etc/nginx/conf-bkp/default.conf
cp /etc/nginx/nginx.conf /etc/nginx/nginx-conf.old
#
# Replace nginx.conf
#
wget https://raw.githubusercontent.com/juliosene/Wordpress-AWS-/master/files/nginx.conf

sed -i "s/#WORKER#/$WORKER/g" nginx.conf
mv nginx.conf /etc/nginx/

# replace Nginx default.conf
#
wget https://raw.githubusercontent.com/juliosene/Wordpress-AWS-/master/files/default.conf
wget https://raw.githubusercontent.com/juliosene/Wordpress-AWS-/master/files/ssl.conf
# sed -i "s,/var/run/php5-fpm.sock,/var/run/php/php7.2-fpm.sock,g" default.conf
mv default.conf /etc/nginx/conf.d/
mv ssl.conf /etc/nginx/conf.d/ssl-conf.exemple

# Do nothing

#
# Edit default page to show php info
#
#mv /usr/share/nginx/html/index.html /usr/share/nginx/html/index.php
mkdir /usr/share/nginx/html/web
#echo -e "<html><title>Azure Nginx PHP</title><body><h2 align='center'>Your Nginx and PHP are running!</h2><h2 align='center'>Host: <?= gethostname() ?></h2></br>\n<?php\nphpinfo();\n?></body>" > /usr/share/nginx/html/web/index.php

cat > /usr/share/nginx/html/web/index.php << _EOF_
<html>
<head>
    <title>Nginx PHP</title>
</head>

<body>
   <h2 align='center'>Your Nginx and PHP are running!</h2>
   <h2 align='center'>Host: <?= gethostname() ?></h2>
   </br>
   <?php
      phpinfo();
   ?>
</body>

</html>
_EOF_

# 
# Install MariaDB
#
if [[ $InstallMariaDB = "yes" ]]
then
    apt-get install -fy pwgen
    apt-get install -fy mariadb-server mariadb-client
    mysql -u root <<EOF
CREATE DATABASE wordpress;
GRANT ALL PRIVILEGES ON wordpress.* TO 'wpuser'@'%'
IDENTIFIED BY '$MyPassword';
FLUSH PRIVILEGES;
EOF
fi
# 
# Install Wordpress
#
if [[ $InstallWordpress = "yes" ]]
then
    apt-get install -fy unzip
    cd /tmp
    wget https://wordpress.org/latest.zip
    unzip latest.zip
    cd wordpress
    mv -f * /usr/share/nginx/html/web/
    echo "Wordpress successfully installed!"
    if [[ $InstallW3TC = "yes" ]]
    then    
        cd /usr/share/nginx/html/web/wp-content/plugins/
        wget https://downloads.wordpress.org/plugin/w3-total-cache.0.9.7.zip
        unzip w3-total-cache.0.9.7.zip && rm w3-total-cache.0.9.7.zip
    fi
    
    if [[ $InstallMariaDB = "yes" ]]
    then  
    AUTH_KEY=`pwgen -ys 64 1`
    SECURE_AUTH_KEY=`pwgen -ys 64 1`
    LOGGED_IN_KEY=`pwgen -ys 64 1`
    NONCE_KEY=`pwgen -ys 64 1`
    AUTH_SALT=`pwgen -ys 64 1`
    SECURE_AUTH_SALT=`pwgen -ys 64 1`
    LOGGED_IN_SALT=`pwgen -ys 64 1`
    NONCE_SALT=`pwgen -ys 64 1`
    
    cat > /usr/share/nginx/html/web/wp-config.php << __EOF__
<?php // ** MySQL settings - You can get this info from your web host ** //
/** The name of the database for WordPress */
define('DB_NAME', 'wordpress');

/** MySQL database username */
define('DB_USER', 'wpuser');

/** MySQL database password */
define('DB_PASSWORD', '$MyPassword');

/** MySQL hostname */
define('DB_HOST', 'localhost');

/** Database Charset to use in creating database tables. */
define('DB_CHARSET', 'utf8mb4');

/** The Database Collate type. Don't change this if in doubt. */
define('DB_COLLATE', '');

 */
define('AUTH_KEY',         '$AUTH_KEY');
define('SECURE_AUTH_KEY',  '$SECURE_AUTH_KEY');
define('LOGGED_IN_KEY',    '$LOGGED_IN_KEY');
define('NONCE_KEY',        '$NONCE_KEY');
define('AUTH_SALT',        '$AUTH_SALT');
define('SECURE_AUTH_SALT', '$SECURE_AUTH_SALT');
define('LOGGED_IN_SALT',   '$LOGGED_IN_SALT');
define('NONCE_SALT',       '$NONCE_SALT');

/**#@-*/

/**
 * WordPress Database Table prefix.
 *
 * You can have multiple installations in one database if you give each
 * a unique prefix. Only numbers, letters, and underscores please!
 */
$table_prefix  = 'wp_';

/**
 * For developers: WordPress debugging mode.
 *
 * Change this to true to enable the display of notices during development.
 * It is strongly recommended that plugin and theme developers use WP_DEBUG
 * in their development environments.
 *
 * For information on other constants that can be used for debugging,
 * visit the Codex.
 *
 * @link https://codex.wordpress.org/Debugging_in_WordPress
 */
define('WP_DEBUG', false);

/* That's all, stop editing! Happy blogging. */

/** Absolute path to the WordPress directory. */
if ( !defined('ABSPATH') )
        define('ABSPATH', dirname(__FILE__) . '/');

/** Sets up WordPress vars and included files. */
require_once(ABSPATH . 'wp-settings.php');
__EOF__

fi
    
    
else
    echo "CMS is not installed!"
fi



#
# Services restart
#

#chown -R nginx.nginx /usr/share/nginx/html/web
chown -R www-data.www-data /usr/share/nginx/html/web

service nginx restart


if [[ $InstallVarnish = "yes" ]]
then
    wget https://raw.githubusercontent.com/juliosene/Wordpress-AWS-/master/install-varnish.sh
    bash ./install-varnish.sh
    echo "Nginx and Varnish installation complete!"

else
    echo "Nginx installation complete!"
fi
