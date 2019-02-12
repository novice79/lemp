# novice/lemp:latest (nginx+php-fpm+mysql three in one)
docker run -p 80:80 -p 3306:3306 -p 33060:33060 -d \
-v /data/php_src:/var/www:rw \
-v /data/mysql:/var/lib/mysql  \
--name lemp -t novice/lemp 

Default mysql root passwd: freego
and with additional default mysql user: 
name: david
pass: freego
and additonal db: lemp
Or you can change it by set these environment variables:
MYSQL_ROOT_PASSWORD     --for root password
MYSQL_USER              --for additional mysql user name
MYSQL_PASSWORD          --for additional mysql user's password
MYSQL_DATABASE          --for additional db name

For example, run container with root password=aaa, 
with another mysql user(name:aaa_user;password:aaa_pass), 
with additional database(aaa_db):
docker run -p 10080:80 -p 3306:3306 -p 33060:33060 -d \
-e MYSQL_ROOT_PASSWORD=aaa \
-e MYSQL_USER=aaa_user \
-e MYSQL_PASSWORD=aaa_pass \
-e MYSQL_DATABASE=aaa_db \
-v /data/php_src:/var/www:rw \
-v /data/mysql:/var/lib/mysql  \
--name lemp -t novice/lemp

# novice/lemp:lumen (nginx+php-fpm+mysql with composer+lumen(5.7.7) demo)
Usage: like above(need to change tag to novice/lemp:lumen of course)
but if mounted "php_src" dir is empty, it will automaticlly create a runnable lumen project here

# novice/lemp:thin (nginx+php-fpm tow in one)
docker run -p 80:80 -d \
-v /data/php_src:/var/www:rw \
--name lep -t novice/lemp:thin