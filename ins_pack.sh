#!/bin/bash
DEBIAN_FRONTEND=noninteractive
sed -i -E "s/^exit [0-9]+$/exit 0/" /usr/sbin/policy-rc.d
apt-get update && apt-get install -y tzdata curl wget procps net-tools \
	ca-certificates apt-transport-https openssh-server

sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd
mkdir -p /var/run/sshd
groupadd sftp
sed -i -E 's@[^[:space:]g]+sftp-server@internal-sftp@' /etc/ssh/sshd_config
cat <<EOT >> /etc/ssh/sshd_config
Match Group sftp
ForceCommand internal-sftp
PasswordAuthentication yes
ChrootDirectory /var
PermitTunnel no
AllowAgentForwarding no
AllowTcpForwarding no
X11Forwarding no
EOT


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

rm -f *.{tar.gz}
mv /wordpress/wp-config-sample.php /wordpress/wp-config.php
# sed "/DB_COLLATE/a define('WPLANG', 'zh_CN');" -i /wordpress/wp-config.php
usermod -aG sftp nobody
mkdir /var/www ; chmod g+w /var/www 
sed '/\[mysqld\]/a default_authentication_plugin=mysql_native_password' -i /etc/mysql/conf.d/docker.cnf
mv /usr/local/lsws/conf/vhosts/{Example,wordpress}
sed -i 's/index\.html/index\.html, index\.php/' /usr/local/lsws/conf/vhosts/wordpress/vhconf.conf
sed -i 's@html/@@' /usr/local/lsws/conf/vhosts/wordpress/vhconf.conf
sed -i 's@Example@wordpress@' /usr/local/lsws/conf/vhosts/wordpress/vhconf.conf
sed -i '/ajax\.googleapis\.com/d' /usr/local/lsws/admin/html.open/view/inc/header.php
rm -rf /usr/local/lsws/Example

rm -- "$0"