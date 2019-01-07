# lemp for dev env (nginx+php-fpm+mysql three in one)
docker run -p 80:80 -p 3306:3306 -p 33060:33060 -d \
-v /data/php_src:/var/www:rw \
-v /data/mysql:/var/lib/mysql  \
--name lemp -t novice/lemp 

# lemp for pro env (nginx+php-fpm tow in one)
docker run -p 80:80 -d \
-v /data/php_src:/var/www:rw \
--name lep -t novice/lemp:thin