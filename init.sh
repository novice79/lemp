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
-- DELETE FROM mysql.user ;
CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}' ;
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
GRANT ALL ON *.* TO 'root'@'%' WITH GRANT OPTION;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL ON *.* TO '$MYSQL_USER'@'%';
CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};
FLUSH PRIVILEGES;
EOT

mysqld_safe --init-file="${sql_init_file}" &
/usr/local/lsws/bin/lshttpd

# no pgrep && ps
while [ 1 ]
do
    sleep 2
    SERVICE="lshttpd"
    if ! pidof "$SERVICE" >/dev/null
    then
        echo "$SERVICE stopped. restart it"
        /usr/local/lsws/bin/lshttpd
    fi

    SERVICE="mysqld"
    if ! pidof "$SERVICE" >/dev/null
    then
        echo "$SERVICE stopped. restart it"
        mysqld_safe --init-file="${sql_init_file}" &
    fi
done