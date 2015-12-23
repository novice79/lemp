FROM ubuntu:latest
MAINTAINER David <david@cninone.com>

# Get noninteractive frontend for Debian to avoid some problems:
#    debconf: unable to initialize frontend: Dialog
ENV DEBIAN_FRONTEND noninteractive

ENV LANG       en_US.UTF-8
ENV LC_ALL	   "en_US.UTF-8"
ENV LANGUAGE   en_US:en

RUN apt-get update && apt-get install -y openssh-server software-properties-common python-software-properties supervisor language-pack-en-base nano

RUN mkdir -p /var/run/sshd /var/log/supervisor /var/log/mysql /var/log/nginx /run/php /var/run/mysqld

RUN echo 'root:freego' | chpasswd
RUN sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

# nginx
RUN printf '%s\n%s\n' "deb http://nginx.org/packages/mainline/ubuntu/ trusty nginx" "deb-src http://nginx.org/packages/mainline/ubuntu/ trusty nginx" >> /etc/apt/sources.list
RUN wget -qO - http://nginx.org/keys/nginx_signing.key | apt-key add -
# php7
RUN add-apt-repository -y ppa:ondrej/php-7.0
# mariadb
ENV MARIADB_MAJOR 5.5
RUN echo 'mariadb-server-$MARIADB_MAJOR mysql-server/root_password password freego' | \
    debconf-set-selections && \
    echo 'mariadb-server-$MARIADB_MAJOR mysql-server/root_password_again password freego' | \
    debconf-set-selections

RUN apt-get update && apt-get install -y nginx php7.0-cli php7.0-common php7.0 php7.0-mysql php7.0-fpm php7.0-curl php7.0-gd mariadb-server \
&& rm -rf /var/lib/apt/lists/* \
	&& rm -rf /var/lib/mysql \
	&& mkdir /var/lib/mysql
# mysql config
RUN sed -i -e"s/^bind-address\s*=\s*127.0.0.1/bind-address = 0.0.0.0/" /etc/mysql/my.cnf

COPY nginx/index.php /var/www/index.php
COPY nginx/default.conf /etc/nginx/conf.d/default.conf
COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY nginx/freego.crt /etc/ssl/freego.crt
COPY nginx/freego.key /etc/ssl/freego.key
RUN chown -R www-data:www-data /var/www
RUN chown -R mysql:mysql /var/lib/mysql /var/log/mysql /var/run/mysqld

VOLUME ["/var/cache/nginx", "/var/lib/mysql"]
EXPOSE 22 80 443 3306

CMD ["/usr/bin/supervisord"]
