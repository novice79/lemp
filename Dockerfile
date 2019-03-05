# base debian:stretch-slim
FROM mysql:latest
LABEL maintainer="David <david@cninone.com>"

COPY ins_pack.sh /ins_pack.sh
RUN /ins_pack.sh

COPY httpd_config.conf /usr/local/lsws/conf/httpd_config.conf
COPY vhconf.conf /usr/local/lsws/conf/vhosts/wordpress/vhconf.conf
COPY letsencrypt /wordpress/wp-content/plugins/letsencrypt
# VOLUME ["/var/www", "/var/lib/mysql"]
WORKDIR /var/www
EXPOSE 22 80 443 3306 33060 7080

COPY init.sh /

ENTRYPOINT ["/init.sh"]
