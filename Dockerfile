FROM novice/build:latest as my_build
WORKDIR /workspace
COPY letsencrypt /workspace/letsencrypt
COPY nodejs /workspace/nodejs
COPY build_app.sh .
RUN /workspace/build_app.sh

# base debian:stretch-slim
FROM mysql:latest
LABEL maintainer="David <david@cninone.com>"

COPY ins_pack.sh /ins_pack.sh
RUN /ins_pack.sh

COPY httpd_config.conf /usr/local/lsws/conf/httpd_config.conf
COPY vhconf.conf /usr/local/lsws/conf/vhosts/wordpress/vhconf.conf

COPY --from=my_build /workspace/letsencrypt /wordpress/wp-content/plugins/letsencrypt
COPY --from=my_build /workspace/app /app

# VOLUME ["/var/www", "/var/lib/mysql"]
WORKDIR /var/www
EXPOSE 22 80 443 3306 33060 7080

COPY init.sh /

ENTRYPOINT ["/init.sh"]
