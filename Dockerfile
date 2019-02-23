FROM debian:stretch-slim
LABEL maintainer="David <david@cninone.com>"

COPY ins_pack.sh /ins_pack.sh
RUN /ins_pack.sh

# VOLUME ["/var/www", "/var/lib/mysql"]
WORKDIR /var/www
EXPOSE 7080 8088 3306

COPY init.sh /

ENTRYPOINT ["/init.sh"]
