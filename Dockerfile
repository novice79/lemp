FROM ubuntu:latest
MAINTAINER David <david@cninone.com>

# Get noninteractive frontend for Debian to avoid some problems:
#    debconf: unable to initialize frontend: Dialog
ENV DEBIAN_FRONTEND noninteractive

ENV LANG       en_US.UTF-8
ENV LC_ALL	   "en_US.UTF-8"
ENV LANGUAGE   en_US:en

RUN apt-get update && apt-get install -y openssh-server \
    software-properties-common python-software-properties supervisor language-pack-en-base \
    curl git vim 

RUN mkdir -p /var/run/sshd /var/log/supervisor /var/log/nginx /run/php 

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
RUN LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php
# mariadb begin
RUN groupadd -r mysql && useradd -r -g mysql mysql
RUN mkdir /docker-entrypoint-initdb.d
RUN apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xcbcb082a1bb943db
RUN add-apt-repository 'deb [arch=amd64,i386] http://sfo1.mirrors.digitalocean.com/mariadb/repo/10.2/ubuntu trusty main'
ENV MARIADB_MAJOR 10.2
RUN { \
		echo mariadb-server-$MARIADB_MAJOR mysql-server/root_password password 'freego'; \
		echo mariadb-server-$MARIADB_MAJOR mysql-server/root_password_again password 'freego'; \
	} | debconf-set-selections \
	&& apt-get update && apt-get install -y nginx php7.0-cli php7.0-common php7.0 php7.0-mysql php7.0-fpm php7.0-curl php7.0-gd mariadb-server \
	&& rm -rf /var/lib/apt/lists/* 
# comment out a few problematic configuration values
# don't reverse lookup hostnames, they are usually another container
RUN sed -Ei 's/^(bind-address|log)/#&/' /etc/mysql/my.cnf \
	&& echo 'skip-host-cache\nskip-name-resolve' | awk '{ print } $1 == "[mysqld]" && c == 0 { c = 1; system("cat") }' /etc/mysql/my.cnf > /tmp/my.cnf \
	&& mv /tmp/my.cnf /etc/mysql/my.cnf
	
# mariadb end

COPY nginx/index.php /var/www/index.php
COPY nginx/default.conf /etc/nginx/conf.d/default.conf
COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY nginx/freego.crt /etc/ssl/freego.crt
COPY nginx/freego.key /etc/ssl/freego.key

RUN chown -R www-data:www-data /var/www

VOLUME ["/var/cache/nginx", "/var/lib/mysql"]

COPY init_mdb.sh /
ENTRYPOINT ["/init_mdb.sh"]

EXPOSE 22 80 443 3306

CMD ["/usr/bin/supervisord"]
