# lemp for dev env
docker run -p 80:80 -p 3306:3306 -p 33060:33060 -d \
-v /data/php_src:/var/www:rw \
-v /data/mysql:/var/lib/mysql  \
--name lemp -t novice/lemp 