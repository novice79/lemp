#!/bin/bash
sed -i -E "s/^exit [0-9]+$/exit 0/" /usr/sbin/policy-rc.d
apt-get update && apt-get install -y tzdata curl wget procps net-tools \
	ca-certificates apt-transport-https 
TZ="Asia/Chongqing"
ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone 

echo "deb http://rpms.litespeedtech.com/debian/ stretch main" > /etc/apt/sources.list.d/lst_debian_repo.list
wget -O /etc/apt/trusted.gpg.d/lst_debian_repo.gpg http://rpms.litespeedtech.com/debian/lst_debian_repo.gpg
wget -O /etc/apt/trusted.gpg.d/lst_repo.gpg http://rpms.litespeedtech.com/debian/lst_repo.gpg

# COPY --from=php:fpm /usr/local /usr/local

apt-get update && apt-get install -y nfs-common unzip \
	openlitespeed lsphp73* \
	&& apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
	; rm -rf /var/lib/apt/lists/* \
	; curl -o /usr/local/bin/composer https://getcomposer.org/download/1.8.4/composer.phar \
	&& chmod +x /usr/local/bin/composer

cd / 
wget https://wordpress.org/latest.tar.gz && tar zxf latest.tar.gz 
mkdir -p /wordpress/wp-content/languages
wget https://downloads.wordpress.org/translation/core/5.0.3/zh_CN.zip && unzip zh_CN.zip -d /wordpress/wp-content/languages
# wget https://cn.wordpress.org/wordpress-5.0.3-zh_CN.tar.gz && tar zxf *.tar.gz
rm -f *.{tar.gz,zip}
mv /wordpress/wp-config-sample.php /wordpress/wp-config.php
sed "/DB_COLLATE/a define('WPLANG', 'zh_CN');" -i /wordpress/wp-config.php

mkdir /var/www ; chown -R www-data:www-data /var/www ;
sed '/\[mysqld\]/a default_authentication_plugin=mysql_native_password' -i /etc/mysql/conf.d/docker.cnf


rm -- "$0"