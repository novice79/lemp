#!/bin/bash
# Taken from the official mysql-repo
# And changed for simplification of course :)
# I.e. DATADIR is always /var/lib/mysql
# We don't force the usage of MYSQL_ALLOW_EMPTY_PASSWORD 
set -e
set -x
# Check ENV (MYSQL_) and stop if they are not known variables
# TODO


tempSqlFile='/tmp/mysql-first-time.sql'
if [ ! -d "/var/lib/mysql/mysql" ]; then
	
	echo 'Running mysql_install_db ...'
	mysql_install_db --datadir=/var/lib/mysql
	echo 'Finished mysql_install_db'
	
	# These statements _must_ be on individual lines, and _must_ end with
	# semicolons (no line breaks or comments are permitted).
	# TODO proper SQL escaping on ALL the things D:
	
	cat > "$tempSqlFile" <<-EOSQL
		-- What's done in this file shouldn't be replicated
		--  or products like mysql-fabric won't work
		SET @@SESSION.SQL_LOG_BIN=0;
		
		DELETE FROM mysql.user ;
		CREATE USER 'root'@'%' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}' ;
		GRANT ALL ON *.* TO 'root'@'%' WITH GRANT OPTION ;
        CREATE USER 'david'@'localhost' IDENTIFIED BY 'freego';
        CREATE USER 'david'@'%' IDENTIFIED BY 'freego';
        GRANT ALL ON *.* TO 'david'@'localhost';
        GRANT ALL ON *.* TO 'david'@'%';
		DROP DATABASE IF EXISTS test ;
	EOSQL


	if [ "$MYSQL_DATABASE" ]; then
		echo "CREATE DATABASE IF NOT EXISTS \`$MYSQL_DATABASE\` ;" >> "$tempSqlFile"
	fi
	
	if [ "$MYSQL_USER" -a "$MYSQL_PASSWORD" ]; then
		echo "CREATE USER '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD' ;" >> "$tempSqlFile"
		echo "CREATE USER '$MYSQL_USER'@'localhost' IDENTIFIED BY '$MYSQL_PASSWORD' ;" >> "$tempSqlFile"
  fi
	if [ "$MYSQL_USER" -a ! "$MYSQL_PASSWORD" ]; then
		echo "CREATE USER '$MYSQL_USER'@'%'  ;"         >> "$tempSqlFile"
		echo "CREATE USER '$MYSQL_USER'@'localhost'  ;" >> "$tempSqlFile"
  fi
		
  if [ "$MYSQL_USER" -a  "$MYSQL_DATABASE"  ]; then
  	echo "GRANT ALL ON \`$MYSQL_DATABASE\`.* TO '$MYSQL_USER'@'%' ;" >> "$tempSqlFile"
  	echo "GRANT ALL ON \`$MYSQL_DATABASE\`.* TO '$MYSQL_USER'@'localhost' ;" >> "$tempSqlFile"
  fi
	
	echo 'FLUSH PRIVILEGES ;' >> "$tempSqlFile"
	
	set -- "$@" --init-file="$tempSqlFile"

fi

echo @a
set -- mysqld "$@"
chown -R mysql:mysql /var/lib/mysql
chown -R mysql:mysql /var/run/mysqld
echo "Checking to upgrade the schema"
echo "A failed upgrade is ok when there was no upgrade"
# mysql_upgrade || true
if grep -q "mysqld" /etc/supervisor/conf.d/supervisord.conf 
then
  echo "already in place, skip it..."
else
  echo "place mysqld in supervisord.conf ..."
  echo "$@" >> /etc/supervisor/conf.d/supervisord.conf
fi

#exec "$@"
exec /usr/bin/supervisord --nodaemon