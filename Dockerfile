# base debian:stretch-slim
FROM mysql:latest
LABEL maintainer="David <david@cninone.com>"

COPY ins_pack.sh /ins_pack.sh
RUN /ins_pack.sh

# can not modify /etc/hosts here 
# VOLUME ["/var/www", "/var/lib/mysql"]
WORKDIR /var/www
EXPOSE 80 443 3306 33060

COPY init.sh /

ENTRYPOINT ["/init.sh"]
