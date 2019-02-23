#!/bin/bash

apt-get update && apt-get install -y tzdata curl wget procps net-tools \
	software-properties-common gnupg2
TZ="Asia/Chongqing"
ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone 

echo "deb http://rpms.litespeedtech.com/debian/ stretch main" > /etc/apt/sources.list.d/lst_debian_repo.list
wget -O /etc/apt/trusted.gpg.d/lst_debian_repo.gpg http://rpms.litespeedtech.com/debian/lst_debian_repo.gpg
wget -O /etc/apt/trusted.gpg.d/lst_repo.gpg http://rpms.litespeedtech.com/debian/lst_repo.gpg

apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8
add-apt-repository 'deb [arch=amd64] http://mirrors.neusoft.edu.cn/mariadb/repo/10.3/debian stretch main'
MARIADB_MAJOR="10.3"
{ \
	echo mariadb-server-$MARIADB_MAJOR mysql-server/root_password password 'freego'; \
	echo mariadb-server-$MARIADB_MAJOR mysql-server/root_password_again password 'freego'; \
} | debconf-set-selections \
&& apt-get update && apt-get install -y openlitespeed mariadb-server lsphp73* 

# apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
# rm -rf /var/lib/apt/lists/* 
cd /usr/local/lsws/admin/misc
ADMIN_USER="david"
PASS_ONE="freego"
ENCRYPT_PASS=`$CUR_DIR/../fcgi-bin/admin_php -q $CUR_DIR/htpasswd.php $PASS_ONE`
echo "$ADMIN_USER:$ENCRYPT_PASS" > $CUR_DIR/../conf/htpasswd 
if [ $? -eq 0 ]; then
	echo "Administrator's username/password is updated successfully!"
fi

rm -- "$0"