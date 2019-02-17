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
CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED WITH mysql_native_password BY '${MYSQL_ROOT_PASSWORD}' ;
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${MYSQL_ROOT_PASSWORD}';
GRANT ALL ON *.* TO 'root'@'%' WITH GRANT OPTION;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED WITH mysql_native_password BY '${MYSQL_PASSWORD}';
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
    echo "empty www directory, create index.php"
    nginx_v=`nginx -v 2>&1`
    mysql_v=`mysql -V`
    cat <<EOT > /var/www/index.php
<!DOCTYPE html> 
<html> 
<head> 
<meta charset="utf-8" /> 
<title>LEMP in docker test</title> 
<style> 
    body{ text-align:center} 
    .version{ margin:0 auto; border:1px solid #F00} 
</style> 
</head> 
<body> 
    lemp versions:
    <div class="version">    
    ${nginx_v}<br>
    ${mysql_v}<br>
    </div> 
    <br>
    <?php echo phpinfo(); ?>
</body> 
</html> 
EOT
elif [ -f "/var/www/public/index.php" ]
then
    sed 's@/var/www@/var/www/public@g' -i /etc/nginx/conf.d/default.conf
else
    echo "normal php www dir containing files, skip"
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