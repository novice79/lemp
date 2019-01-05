# [nginx, mysql, php-fpm] all in debian:stretch-slim
# so just copy them together
FROM mysql:latest
LABEL maintainer="David <david@cninone.com>"

RUN apt-get update && apt-get install -y tzdata \
    && rm -rf /var/lib/apt/lists/*
ENV TZ=Asia/Chongqing
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

COPY --from=php:fpm / /
COPY --from=nginx:latest / /

COPY conf/default.conf /etc/nginx/conf.d/default.conf
COPY conf/nginx.conf /etc/nginx/nginx.conf
RUN chown -R www-data:www-data /var/www
VOLUME ["/var/www", "/var/lib/mysql"]

EXPOSE 80 3306 33060

COPY init /

ENTRYPOINT ["/init"]
