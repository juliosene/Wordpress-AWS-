#!/bin/bash
# Install Nginx
cd ~
# apt-get update
# apt-get -fy dist-upgrade
# apt-get -fy upgrade
apt-get install lsb-release bc
REL=`lsb_release -sc`
DISTRO=`lsb_release -is | tr [:upper:] [:lower:]`
NCORES=` cat /proc/cpuinfo | grep cores | wc -l`
WORKER=`bc -l <<< "4*$NCORES"`

AppToInstall=${1:-"none"}
# wordpres, joomla, drupal
PHPVersion=${2-7}


InstallTools=${3:-"no"}
ToolsUser=$4
ToolsPass=$5

wget http://nginx.org/keys/nginx_signing.key
apt-key add nginx_signing.key
add-apt-repository "deb http://nginx.org/packages/$DISTRO $REL nginx"
# add-apt-repository "deb-src http://nginx.org/packages/$DISTRO $REL nginx"
if [ "$PHPVersion" -eq 7 ]; then
apt-get install -fy python-software-properties
LC_ALL=en_US.UTF-8 add-apt-repository ppa:ondrej/php -y
fi

apt-get -y update

# apt-get install -y -f cifs-utils

apt-get install -fy nginx
# # PHP 7
if [ "$PHPVersion" -eq 7 ]; then
apt-get install php7.0 php7.0-fpm php7.0-mysql -y
apt-get install -fy php7.0-gd php7.0-curl php7.0-mbstring php7.0-xml
# apt-get install -fy php-apc php7.0-gd
apt-get --purge autoremove -y
# replace www-data to nginx into /etc/php/7.0/fpm/pool.d/www.conf
sed -i 's/www-data/nginx/g;s/\;request_terminate_timeout = 0/request_terminate_timeout = 300/g;' /etc/php/7.0/fpm/pool.d/www.conf
service php7.0-fpm restart
# # PHP 5
else
apt-get install -fy php5-fpm php5-cli php5-mysql
apt-get install -fy php-apc php5-gd php5-mbstring
# replace www-data to nginx into /etc/php5/fpm/pool.d/www.conf
sed -i 's/www-data/nginx/g;s/\;request_terminate_timeout = 0/request_terminate_timeout = 300/g;' /etc/php5/fpm/pool.d/www.conf
service php5-fpm restart
fi

# backup default Nginx configuration
mkdir /etc/nginx/conf-bkp
cp /etc/nginx/conf.d/default.conf /etc/nginx/conf-bkp/default.conf
cp /etc/nginx/nginx.conf /etc/nginx/nginx-conf.old
#
# Replace nginx.conf
#
wget https://raw.githubusercontent.com/juliosene/azure-nginx-php-mariadb-cluster/master/files/nginx.conf

sed -i "s/#WORKER#/$WORKER/g" nginx.conf
mv nginx.conf /etc/nginx/

# replace Nginx default.conf
#
wget https://raw.githubusercontent.com/juliosene/azure-nginx-php-mariadb-cluster/master/files/default.conf

# replace for php7 sock
if [ "$PHPVersion" -eq 7 ]; then
sed -i "s,/var/run/php5-fpm.sock,/var/run/php/php7.0-fpm.sock,g" default.conf
fi

#sed -i "s/#WORKER#/$WORKER/g" nginx.conf
mv default.conf /etc/nginx/conf.d/

# Memcache client installation
# ## php 7
if [ "$PHPVersion" -eq 7 ]; then
apt-get install -fy php-memcached
# wget https://raw.githubusercontent.com/juliosene/azure-nginx-php-mariadb-cluster/master/files/memcache.ini
# mv memcache.ini /etc/php/mods-available/
# ln -s /etc/php/mods-available/memcache.ini  /etc/php/7.0/fpm/conf.d/20-memcache.ini
# ## php 5
else
apt-get install -fy php-pear
apt-get install -fy php5-dev
printf "\n" |pecl install -f memcache
wget https://raw.githubusercontent.com/juliosene/azure-nginx-php-mariadb-cluster/master/files/memcache.ini
#sed -i "s/#WORKER#/$WORKER/g" memcache.ini
mv memcache.ini /etc/php5/mods-available/
ln -s /etc/php5/mods-available/memcache.ini  /etc/php5/fpm/conf.d/20-memcache.ini
fi



if [ $AppToInstall == "wordpress" ];
then
# Install wordpress
cd /usr/share/nginx/html/
wget https://wordpress.org/latest.tar.gz
tar -xzvf latest.tar.gz
mv wordpress web
rm -rf latest.tar.gz

elif [ $AppToInstall == "joomla" ];
then
# Install joomla
cd /usr/share/nginx/html/
wget https://github.com/joomla/joomla-cms/releases/download/3.6.2/Joomla_3.6.2-Stable-Full_Package.tar.gz
mkdir /usr/share/nginx/html/web
cd web
tar -xzvf latest.tar.gztar -xzvf ../Joomla_3.6.2-Stable-Full_Package.tar.gz
cd ..
rm -rf Joomla_3.6.2-Stable-Full_Package.tar.gz

elif [ $AppToInstall == "drupal" ];
then
# Install drupal
cd /usr/share/nginx/html/
wget https://ftp.drupal.org/files/projects/drupal-8.2.1.tar.gz
tar -xzvf drupal-8.2.1.tar.gz
mv drupal-8.2.1 web
rm -rf drupal-8.2.1.tar.gz

else
# Do nothing

#
# Edit default page to show php info
#
#mv /usr/share/nginx/html/index.html /usr/share/nginx/html/index.php
mkdir /usr/share/nginx/html/web
echo -e "<html><title>Azure Nginx PHP</title><body><h2 align='center'>Your Nginx and PHP are running!</h2><h2 align='center'>Host: <?= gethostname() ?></h2></br>\n<?php\nphpinfo();\n?></body>" > /usr/share/nginx/html/web/index.php

fi

#
#
# Install admin tools
if [ $InstallTools == "yes" ];
then
   wget https://raw.githubusercontent.com/juliosene/azure-nginx-php-mariadb-cluster/master/tools/install-tools.sh
   bash install-tools.sh $ToolsUser $ToolsPass
fi


if [ $InstallTools == "yes" ];
then
if [ $OPTION -gt 0 ]; 
then  
wget https://raw.githubusercontent.com/juliosene/azure-nginx-php-mariadb-cluster/master/tools/tools.conf
mv tools.conf /etc/nginx/conf.d/
fi
fi

#
# Services restart
#
if [ "$PHPVersion" -eq 7 ]; then
sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 100M/g;s/post_max_size = 8M/post_max_size = 64M/g;s/max_execution_time = 30/max_execution_time = 300/g" /etc/php/7.0/fpm/php.ini
service php7.0-fpm restart
else
sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 100M/g;s/post_max_size = 8M/post_max_size = 64M/g;s/max_execution_time = 30/max_execution_time = 300/g" /etc/php5/fpm/php.ini
service php5-fpm restart
fi

chown -R nginx.nginx /usr/share/nginx/html/web

service nginx restart
