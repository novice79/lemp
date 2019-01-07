# base debian:stretch-slim
FROM mysql:latest
LABEL maintainer="David <david@cninone.com>"

RUN apt-get update && apt-get install -y tzdata curl wget procps net-tools \
	ca-certificates apt-transport-https 
ENV TZ=Asia/Chongqing
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone 

# nginx begin
RUN printf '%s\n' "deb http://nginx.org/packages/mainline/debian/ stretch nginx" >> /etc/apt/sources.list
RUN curl http://nginx.org/keys/nginx_signing.key | apt-key add -
# nginx end

# COPY --from=php:fpm /usr/local /usr/local
# php begin
RUN wget -q https://packages.sury.org/php/apt.gpg -O- | apt-key add - \
	&& echo "deb https://packages.sury.org/php/ stretch main" | tee /etc/apt/sources.list.d/php.list
# php end
RUN apt-get update && apt-get install -y nginx \
	php7.3 php7.3-bcmath php7.3-bz2 php7.3-cli php7.3-common php7.3-curl php7.3-dba php7.3-dev php7.3-enchant \
	php7.3-fpm php7.3-gd php7.3-gmp php7.3-imap php7.3-intl php7.3-json php7.3-mbstring php7.3-mysql php7.3-odbc \
	php7.3-opcache php7.3-pgsql php7.3-readline \
	php7.3-soap php7.3-sqlite3 php7.3-tidy php7.3-xml php7.3-xmlrpc php7.3-zip php-redis php-igbinary php-mongodb \
	&& apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
	; rm -rf /var/lib/apt/lists/* 

COPY conf/nginx/default.conf /etc/nginx/conf.d/default.conf
COPY conf/nginx/nginx.conf /etc/nginx/nginx.conf

RUN mkdir /var/www /run/php && chown -R www-data:www-data /var/www && ln -sf /usr/sbin/php-fpm7.3 /usr/sbin/php-fpm ; \
	sed 's@^listen = /run.*$@listen = 127.0.0.1:9000@g' -i /etc/php/7.3/fpm/pool.d/www.conf
	
VOLUME ["/var/www", "/var/lib/mysql"]

EXPOSE 80 3306 33060

COPY init /

ENTRYPOINT ["/init"]
