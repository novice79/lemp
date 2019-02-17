#!/bin/bash
sed -i -E "s/^exit [0-9]+$/exit 0/" /usr/sbin/policy-rc.d
apt-get update && apt-get install -y tzdata curl wget procps net-tools \
	ca-certificates apt-transport-https 
TZ="Asia/Chongqing"
ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone 

# nginx begin
printf '%s\n' "deb http://nginx.org/packages/mainline/debian/ stretch nginx" >> /etc/apt/sources.list
curl http://nginx.org/keys/nginx_signing.key | apt-key add -
# nginx end

# COPY --from=php:fpm /usr/local /usr/local
# php begin
wget -q https://packages.sury.org/php/apt.gpg -O- | apt-key add - \
	&& echo "deb https://packages.sury.org/php/ stretch main" | tee /etc/apt/sources.list.d/php.list
# php end
apt-get update && apt-get install -y nginx nfs-common unzip \
	php7.3 php7.3-bcmath php7.3-bz2 php7.3-cli php7.3-common php7.3-curl php7.3-dba php7.3-dev php7.3-enchant \
	php7.3-fpm php7.3-gd php7.3-gmp php7.3-imap php7.3-intl php7.3-json php7.3-mbstring php7.3-mysql php7.3-odbc \
	php7.3-opcache php7.3-pgsql php7.3-readline \
	php7.3-soap php7.3-sqlite3 php7.3-tidy php7.3-xml php7.3-xmlrpc php7.3-zip php-redis php-igbinary php-mongodb \
	&& apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
	; rm -rf /var/lib/apt/lists/* \
	; curl -o /usr/local/bin/composer https://getcomposer.org/download/1.8.4/composer.phar \
	&& chmod +x /usr/local/bin/composer

cd / && wget https://wordpress.org/latest.tar.gz && tar zxf latest.tar.gz 
mkdir -p /wordpress/wp-content/languages
wget https://downloads.wordpress.org/translation/core/5.0.3/zh_CN.zip && unzip zh_CN.zip -d /wordpress/wp-content/languages
rm -f *.{tar.gz,zip}
mv /wordpress/wp-config-sample.php /wordpress/wp-config.php
sed "/DB_COLLATE/a define('WPLANG', 'zh_CN');" -i /wordpress/wp-config.php

mkdir /var/www ; chown -R www-data:www-data /var/www ; ln -sf /usr/sbin/php-fpm7.3 /usr/sbin/php-fpm ; \
	sed 's@^listen = /run.*$@listen = 127.0.0.1:9000@g' -i /etc/php/7.3/fpm/pool.d/www.conf ; \
	sed '/\[mysqld\]/a default_authentication_plugin=mysql_native_password' -i /etc/mysql/conf.d/docker.cnf


rm -- "$0"