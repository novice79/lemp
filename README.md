# lemp
for docker hub auto build
# build locally
docker build -t novice/lemp .
# run it like this
docker run -p 222:22 -p 80:80 -p 3306:3306 -d -v /my_php_site_src_path:/var/www:rw -v /my/own/datadir:/var/lib/mysql -e MYSQL_ROOT_PASSWORD=freego --name fg -t novice/lemp
ssh root user pass: *freego*
and test it:
$curl $(docker-machine ip default)
$ssh root@$(docker-machine ip default) -p 222
root@192.168.99.100's password:freego
root@1d0f67e86996:~# 

