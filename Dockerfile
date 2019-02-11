# base debian:stretch-slim
FROM mysql:latest
LABEL maintainer="David <david@cninone.com>"

COPY ins_pack.sh /ins_pack.sh
RUN /ins_pack.sh
# need first install nginx, and then copy conf files
COPY conf/nginx/default.conf /etc/nginx/conf.d/default.conf
COPY conf/nginx/nginx.conf /etc/nginx/nginx.conf

# can not modify /etc/hosts here 
# VOLUME ["/var/www", "/var/lib/mysql"]
WORKDIR /var/www
EXPOSE 80 3306 33060

COPY init.sh /

ENTRYPOINT ["/init.sh"]
