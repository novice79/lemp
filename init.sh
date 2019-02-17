#!/bin/bash
log () {
    printf "[%(%Y-%m-%d %T)T] %s\n" -1 "$*"
}
echo () {
    log "$@"
}
chown -R mysql:mysql /var/lib/mysql
if [ ! -e /var/lib/mysql/mysql ]; then
    rm -rf /var/lib/mysql/*
    mysqld --initialize --user=mysql --datadir=/var/lib/mysql
fi
export sql_init_file='/tmp/mysql-init.sql'
# get environment variables:
echo "MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD:=freego}"
echo "MYSQL_USER=${MYSQL_USER:=david}"
echo "MYSQL_PASSWORD=${MYSQL_PASSWORD:=freego}"
echo "MYSQL_DATABASE=${MYSQL_DATABASE:=lemp}"
cat <<EOT > $sql_init_file
CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}' ;
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
GRANT ALL ON *.* TO 'root'@'%' WITH GRANT OPTION;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL ON *.* TO '$MYSQL_USER'@'%';
CREATE USER IF NOT EXISTS 'slaveuser'@'%' IDENTIFIED WITH sha256_password BY 'freego';
GRANT REPLICATION SLAVE ON *.* TO 'slaveuser'@'%';
CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};
FLUSH PRIVILEGES;
EOT
su mysql -c '/usr/sbin/mysqld --init-file="${sql_init_file}" --server-id=1 --log-bin=mysql-bin --gtid-mode=ON --enforce-gtid-consistency=true --log-slave-updates &'
# ignore hidden files
if [ -z "$(ls /var/www)" ]
then
    echo "empty www directory, create wordpress site"
    cp -a /wordpress/. /var/www/
    sed -i "s/database_name_here/$MYSQL_DATABASE/" /var/www/wp-config.php
    sed -i "s/username_here/$MYSQL_USER/" /var/www/wp-config.php
    sed -i "s/password_here/$MYSQL_PASSWORD/" /var/www/wp-config.php
    for i in {1..8}; do 
        APP_KEY=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
        sed -i "0,/put your unique phrase here/ s//$APP_KEY/" /var/www/wp-config.php
    done
else
  echo "contains files, skip"
fi
php-fpm -F &
# pid_php=$!
nginx &
# pid_nginx=$!

# no pgrep && ps
while [ 1 ]
do
    sleep 2
    SERVICE="nginx"
    if ! pidof "$SERVICE" >/dev/null
    then
        echo "$SERVICE stopped. restart it"
        "$SERVICE" &
        # send mail ?
    fi
    SERVICE="php-fpm"
    if ! pidof "$SERVICE" >/dev/null
    then
        echo "$SERVICE stopped. restart it"
        "$SERVICE" -F &
        # send mail ?
    fi
    SERVICE="mysqld"
    if ! pidof "$SERVICE" >/dev/null
    then
        echo "$SERVICE stopped. restart it"
        su mysql -c '/usr/sbin/mysqld --init-file="${sql_init_file}" --server-id=1 --log-bin=mysql-bin --gtid-mode=ON --enforce-gtid-consistency=true --log-slave-updates &'
        # send mail ?
    fi
done