FROM debian:stretch-slim
LABEL maintainer="David <david@cninone.com>"

COPY ins_pack.sh /ins_pack.sh
RUN /ins_pack.sh
COPY httpd_config.conf /usr/local/lsws/conf/httpd_config.conf
# VOLUME ["/usr/local/lsws/Example/html", "/var/lib/mysql"]
WORKDIR /usr/local/lsws/Example/html
EXPOSE 7080 8088 3306

COPY init.sh /

ENTRYPOINT ["/init.sh"]
