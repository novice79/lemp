## novice/lemp:latest (nginx+php-fpm+mysql *three in one*)
In a workspace dir  
>mkdir php_src mysql  

and then run:

    docker run -p 10080:80 -p 3306:3306 -p 33060:33060 -d \
    -v $PWD/php_src:/var/www:rw \
    -v $PWD/mysql:/var/lib/mysql  \
    --name lemp -t novice/lemp 

Default mysql root passwd: **freego**  
and with additional ***default*** mysql user:  
**name: david  
password: freego**  
and additonal db: **lemp**  
Or you can change it by set these environment variables:  

    MYSQL_ROOT_PASSWORD     --for mysql root password  
    MYSQL_USER              --for additional mysql user name  
    MYSQL_PASSWORD          --for additional mysql user's password  
    MYSQL_DATABASE          --for additional db name  

For example, to run a container with  
root password = aaa,  
with another mysql user = (name:aaa_user, password:aaa_pass),  
with additional database = aaa_db  

    docker run -p 10080:80 -p 3306:3306 -p 33060:33060 -d \
    -e MYSQL_ROOT_PASSWORD=aaa \
    -e MYSQL_USER=aaa_user \
    -e MYSQL_PASSWORD=aaa_pass \
    -e MYSQL_DATABASE=aaa_db \
    -v $PWD/php_src:/var/www:rw \
    -v $PWD/mysql:/var/lib/mysql  \
    --name lemp -t novice/lemp

And you can overwite **nginx config file** by add:
>-v host_dir/mysite.conf:/etc/nginx/conf.d/default.conf

## novice/lemp:lumen (above with composer+lumen(5.7.7) skeleton )
Usage:  
like above(need to change tag to novice/lemp:lumen of course)  
but if mounted "php_src" dir is empty, it will automaticlly create a runnable lumen project here  
just open browser to http://host-ip:10080 to see it,   
and change generated code in "php_src" to startup

## novice/lemp:wp (lemp with wordpress(chinese version 5.0.3)  )
Usage:  
like above(need to change tag to novice/lemp:wp of course)  

## novice/lemp:ols (OpenLiteSpeed1.4.44 + php7.3.2 + mariadb10.3.13 )
Usage:  
In a workspace dir  
>mkdir php_src mysql  

and then run:

    docker run -p 10080:8088 -p 7080:7080 -p 3060:3060 -d \
    -v $PWD/php_src:/usr/local/lsws/Example/html \
    -v $PWD/mysql:/var/lib/mysql  \
    -v lsconf:/usr/local/lsws/conf \
    --name lemp -t novice/lemp:ols

There are something you can change by define these env variables: 

    MYSQL_ROOT_PASSWORD     --for mysql root password(default: freego) 
    MYSQL_USER              --for another mysql user name(default: david)  
    MYSQL_PASSWORD          --for another mysql user's password(default: freego)  
    MYSQL_DATABASE          --for another db name(default: lemp)  
    LS_USER                 --for OpenLiteSpeed admin username(default: david)  
    LS_PASS                 --for OpenLiteSpeed admin password(default: freego)  
 and if you want to retain litespeed config data between rm and rerun, remember mount named volume to '/usr/local/lsws/conf'
## novice/lemp:thin (nginx+php-fpm *tow in one*)
This need to connect to external db  

    docker run -p 10080:80 -d \
    -v $PWD/php_src:/var/www:rw \
    --name lep -t novice/lemp:thin