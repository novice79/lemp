#!/bin/bash
log () {
    printf "[%(%Y-%m-%d %T)T] %s\n" -1 "$*"
}

chown -R mysql:mysql /var/lib/mysql
if [ ! -e /var/lib/mysql/mysql ]; then
    rm -rf /var/lib/mysql/*
    mysql_install_db --datadir=/var/lib/mysql
fi
export sql_init_file='/tmp/mysql-init.sql'
# get environment variables:
log "MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD:=freego}"
log "MYSQL_USER=${MYSQL_USER:=david}"
log "MYSQL_PASSWORD=${MYSQL_PASSWORD:=freego}"
log "MYSQL_DATABASE=${MYSQL_DATABASE:=lemp}"
cat <<EOT > $sql_init_file
-- DELETE FROM mysql.user ;
CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}' ;
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
GRANT ALL ON *.* TO 'root'@'%' WITH GRANT OPTION;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL ON *.* TO '$MYSQL_USER'@'%';
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'localhost' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL ON *.* TO '$MYSQL_USER'@'localhost';
CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};
FLUSH PRIVILEGES;
EOT

cd /usr/local/lsws/admin/misc
log "LS_USER=${LS_USER:=david}"
log "LS_PASS=${LS_PASS:=freego}"
CUR_DIR=`pwd`
ENCRYPT_PASS=`$CUR_DIR/../fcgi-bin/admin_php -q $CUR_DIR/htpasswd.php $LS_PASS`
echo "$LS_USER:$ENCRYPT_PASS" > $CUR_DIR/../conf/htpasswd 
if [ $? -eq 0 ]; then
	log "OpenLiteSpeed administrator's username/password is updated successfully!"
fi
# /usr/local/lsws/lsphp73/bin/lsphp	
mysqld --init-file="${sql_init_file}" --user=root &
/usr/local/lsws/bin/lshttpd

# no pgrep && ps
while :
do
    sleep 2
    SERVICE="lshttpd"
    if ! pidof "$SERVICE" >/dev/null; then
        log "$SERVICE stopped. restart it"
        /usr/local/lsws/bin/lshttpd
    fi

    SERVICE="mysqld"
    if ! pidof "$SERVICE" >/dev/null; then
        log "$SERVICE stopped. restart it"
        mysqld_safe --init-file="${sql_init_file}" &
    fi
done