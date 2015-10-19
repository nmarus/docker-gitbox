#gitbox with gitlist v.0.5.0
FROM ubuntu:trusty
MAINTAINER Nick Marus <nmarus@gmail.com>

#Setup enviroment variables
ENV CNAME="gitbox"
ENV ADMIN="gitadmin"

#Setup Container
VOLUME ["/repos"]
VOLUME ["/ng-auth"]
EXPOSE 80

#update, install prerequisites, clean up apt
RUN DEBIAN_FRONTEND=noninteractive apt-get -y update && \
	apt-get -y install git wget nginx-full php5-fpm fcgiwrap apache2-utils && \
	apt-get clean

#setup user for nginx services
RUN useradd -M -s /bin/false git --uid 1000

#setup nginx services to run as user git, group git
RUN sed -i 's/user = www-data/user = git/g' /etc/php5/fpm/pool.d/www.conf && \
	sed -i 's/group = www-data/group = git/g' /etc/php5/fpm/pool.d/www.conf && \
	sed -i 's/listen.owner = www-data/listen.owner = git/g' /etc/php5/fpm/pool.d/www.conf && \
	sed -i 's/listen.group = www-data/listen.group = git/g' /etc/php5/fpm/pool.d/www.conf && \
	sed -i 's/FCGI_USER="www-data"/FCGI_USER="git"/g' /etc/init.d/fcgiwrap && \
	sed -i 's/FCGI_GROUP="www-data"/FCGI_GROUP="git"/g' /etc/init.d/fcgiwrap && \
	sed -i 's/FCGI_SOCKET_OWNER="www-data"/FCGI_SOCKET_OWNER="git"/g' /etc/init.d/fcgiwrap && \
	sed -i 's/FCGI_SOCKET_GROUP="www-data"/FCGI_SOCKET_GROUP="git"/g' /etc/init.d/fcgiwrap

#install gitlist
RUN mkdir -p /var/www && \
	wget -q -O /var/www/gitlist-0.5.0.tar.gz https://s3.amazonaws.com/gitlist/gitlist-0.5.0.tar.gz && \
	tar -zxvf /var/www/gitlist-0.5.0.tar.gz -C /var/www && \
	chmod -R 777 /var/www/gitlist && \
	mkdir -p /var/www/gitlist/cache && \
	chmod 777 /var/www/gitlist/cache

#create config files for container startup, gitlist, and nginx
COPY start.sh /start.sh
COPY config.ini /var/www/gitlist/config.ini
COPY nginx.conf /etc/nginx/nginx.conf
COPY repo-admin.sh /usr/local/bin/repo-admin
COPY ng-auth.sh /usr/local/bin/ng-auth
RUN chmod +x /start.sh && \
	chmod +x /usr/local/bin/repo-admin && \
	chmod +x /usr/local/bin/ng-auth

CMD ["/start.sh"]
