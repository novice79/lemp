#!/bin/bash
log () {
    printf "[%(%Y-%m-%d %T)T] %s\n" -1 "$*"
}

chown -R mysql:mysql /var/lib/mysql
if [ ! -e /var/lib/mysql/mysql ]; then
    rm -rf /var/lib/mysql/*
    mysqld --initialize --user=mysql --datadir=/var/lib/mysql
fi
export sql_init_file='/tmp/mysql-init.sql'
# get environment variables:
log "MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD:=freego}"
log "MYSQL_USER=${MYSQL_USER:=david}"
log "MYSQL_PASSWORD=${MYSQL_PASSWORD:=freego}"
log "MYSQL_DATABASE=${MYSQL_DATABASE:=lemp}"
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
cd /usr/local/lsws/admin/misc
log "LS_USER=${LS_USER:=david}"
log "LS_PASS=${LS_PASS:=freego}"
CUR_DIR=`pwd`
ENCRYPT_PASS=`$CUR_DIR/../fcgi-bin/admin_php -q $CUR_DIR/htpasswd.php $LS_PASS`
echo "$LS_USER:$ENCRYPT_PASS" > $CUR_DIR/../conf/htpasswd 
if [ $? -eq 0 ]; then
	log "OpenLiteSpeed administrator's username/password is updated successfully!"
fi
# before start sshd
log "SFTP_USER=${SFTP_USER:=david}"
log "SFTP_PASS=${SFTP_PASS:=freego}"
useradd -d /var/www "${SFTP_USER}" -g sftp
echo "${SFTP_USER}:${SFTP_PASS}" | chpasswd

# ignore hidden files
# if [ -z "$(ls /var/www)" ]
if [ ! -d "/var/www/wordpress" ]
then
    log "has no yet wordpress site, create it"
    WP_CFG="/var/www/wordpress/wp-config.php"
    # cp -a /wordpress/. /var/www/
    cp -a /wordpress /var/www/
    chmod -R g+w /var/www/wordpress
    sed -i "s/database_name_here/$MYSQL_DATABASE/" $WP_CFG
    sed -i "s/username_here/$MYSQL_USER/" $WP_CFG
    sed -i "s/password_here/$MYSQL_PASSWORD/" $WP_CFG
    for i in {1..8}; do 
        APP_KEY=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
        sed -i "0,/put your unique phrase here/ s//$APP_KEY/" $WP_CFG
    done
    sed '/^.*DB_COLLATE.*$/r'<(
        echo "define( 'FS_METHOD', 'direct' );"
        echo "define( 'FTP_BASE', dirname( __FILE__ ) );"
        echo "define( 'FTP_USER', '${SFTP_USER}' );"
        echo "define( 'FTP_PASS', '${SFTP_PASS}' );"
        echo "define( 'FTP_HOST', 'localhost' );"
        echo "define( 'FTP_SSL', true );"
    ) -i -- $WP_CFG
else
  log "wordpress already exist, skip"
fi
chown -R "${SFTP_USER}":sftp /var/www
/usr/sbin/sshd
/usr/sbin/mysqld --init-file="${sql_init_file}" --user=root --server-id=1 --log-bin=mysql-bin --gtid-mode=ON --enforce-gtid-consistency=true --log-slave-updates &
/usr/local/lsws/bin/lshttpd
# no pgrep && ps
while [ 1 ]
do
    sleep 2
    SERVICE="mysqld"
    if ! pidof "$SERVICE" >/dev/null
    then
        echo "$SERVICE stopped. restart it"
        /usr/sbin/mysqld --init-file="${sql_init_file}" --user=root --server-id=1 --log-bin=mysql-bin --gtid-mode=ON --enforce-gtid-consistency=true --log-slave-updates &
        # send mail ?
    fi
done