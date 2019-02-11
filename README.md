# lemp for dev env (nginx+php-fpm+mysql three in one)
docker run -p 80:80 -p 3306:3306 -p 33060:33060 -d \
-v /data/php_src:/var/www:rw \
-v /data/mysql:/var/lib/mysql  \
--name lemp -t novice/lemp 

default mysql root passwd: freego
and with additional mysql user: 
name: david
pass: freego
or you can change root password by set it in MYSQL_ROOT_PASSWORD env
or add another user and database by supply MYSQL_USER MYSQL_PASSWORD MYSQL_DATABASE environment variables

for example, run container with root password=aaa, with another mysql user(name:aaa_user;password:aaa_pass), with additional database(aaa_db):
docker run -p 80:80 -p 3306:3306 -p 33060:33060 -d \
-e MYSQL_ROOT_PASSWORD=aaa \
-e MYSQL_USER=aaa_user \
-e MYSQL_PASSWORD=aaa_pass \
-e MYSQL_DATABASE=aaa_db \
-v /data/php_src:/var/www:rw \
-v /data/mysql:/var/lib/mysql  \
--name lemp -t novice/lemp

# lemp for pro env (nginx+php-fpm tow in one)
docker run -p 80:80 -d \
-v /data/php_src:/var/www:rw \
--name lep -t novice/lemp:thin