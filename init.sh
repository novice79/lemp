#!/bin/bash

# ignore hidden files
if [ -z "$(ls /var/www)" ]
then
    echo "empty www directory, create index.php"
    nginx_v=`nginx -v 2>&1`
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
    </div> 
    <br>
    <?php echo phpinfo(); ?>
</body> 
</html> 
EOT
elif [ -f "/var/www/public/index.php" ] && grep -q "docker stock config" /etc/nginx/conf.d/default.conf
then
    echo "change doc dir to public ..."
    sed 's@/var/www;@/var/www/public;@g' -i /etc/nginx/conf.d/default.conf
else
    echo "normal php www dir containing files, skip"
fi
# too slow, so comment out
# if [ -f "/var/www/composer.json" ]; then
#     cd /var/www && composer install
# fi
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
done