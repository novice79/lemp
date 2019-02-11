#!/bin/bash
chown -R mysql:mysql /var/lib/mysql
if [ ! -e /var/lib/mysql/mysql ]; then
    rm -rf /var/lib/mysql/*
    mysqld --initialize --user=mysql --datadir=/var/lib/mysql
fi
export sql_init_file='/tmp/mysql-init.sql'
# get environment variables:
cat <<EOT > $sql_init_file
CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD:=freego}' ;
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD:=freego}';
GRANT ALL ON *.* TO 'root'@'%' WITH GRANT OPTION;
CREATE USER IF NOT EXISTS '${MYSQL_USER:=david}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD:=freego}';
GRANT ALL ON *.* TO '$MYSQL_USER'@'%';
CREATE USER IF NOT EXISTS 'slaveuser'@'%' IDENTIFIED WITH sha256_password BY 'freego';
GRANT REPLICATION SLAVE ON *.* TO 'slaveuser'@'%';
${MYSQL_DATABASE:+"CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};"}
FLUSH PRIVILEGES;
EOT
su mysql -c '/usr/sbin/mysqld --init-file="${sql_init_file}" --server-id=1 --log-bin=mysql-bin --gtid-mode=ON --enforce-gtid-consistency=true --log-slave-updates &'

if [ -n "$(find /var/www -prune -empty -type d 2>/dev/null)" ]
then
  echo "empty www directory, create lumen demo"
  cp -a /lumen/. /var/www/
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