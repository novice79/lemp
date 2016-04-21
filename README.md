# lemp
for docker lemp galera test
# build locally
docker build -t novice/lemp .
# run it like this
suppose following 3 nodes
n_1 10.10.10.10
n_2 10.10.10.11
n_3 10.10.10.12
A simple cluster setup would look like this:

n_1$ docker run -p 222:22 -p 80:80 -p 3306:3306 -p 4567:4567 -p 4444:4444 -p 4568:4568 -d \
-v /my_php_site_src_path:/var/www:rw \
-v /my/own/datadir:/var/lib/mysql  \
--name n_1 -t novice/lemp \
--wsrep-cluster-address=gcomm:// --wsrep-node-address=10.10.10.10

n_2$ docker run -d -p 222:22 -p 80:80 -p 3306:3306 -p 4567:4567 -p 4444:4444 -p 4568:4568 \
--name n_2 -t novice/lemp 
--wsrep-cluster-address=gcomm://10.10.10.10 --wsrep-node-address=10.10.10.11

n_3$ docker run -d -p 222:22 -p 80:80 -p 3306:3306 -p 4567:4567 -p 4444:4444 -p 4568:4568 \
--name n_3 -t novice/lemp 
--wsrep-cluster-address=gcomm://10.10.10.10 --wsrep-node-address=10.10.10.12

n_1$ docker exec -t n_1 mysql -uroot -pfreego -e 'show status like "wsrep_cluster_size"'
+--------------------+-------+
| Variable_name      | Value |
+--------------------+-------+
| wsrep_cluster_size |     3 |
+--------------------+-------+


