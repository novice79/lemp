# lemp
for docker lemp galera test
# build locally
docker build -t novice/lemp .
# run it like this
suppose following 3 nodes

nodea 10.10.10.10
nodeb 10.10.10.11
nodec 10.10.10.12
A simple cluster setup would look like this:

nodea$ docker run -p 222:22 -p 80:80 -p 3306:3306 -p 4567:4567 -p 4444:4444 -p 4568:4568 -d \
-v /my_php_site_src_path:/var/www:rw \
-v /my/own/datadir:/var/lib/mysql  --name fg -t novice/lemp \
--wsrep-cluster-address=gcomm:// --wsrep-node-address=10.10.10.10

ssh root user pass: *freego*
and test it:
$curl $(docker-machine ip default)
$ssh root@$(docker-machine ip default) -p 222
root@192.168.99.100's password:freego
root@1d0f67e86996:~# 

