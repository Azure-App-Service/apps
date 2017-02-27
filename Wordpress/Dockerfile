#
# Dockerfile for WordPress
#
FROM ubuntu:16.04
LABEL maintainer "v-jifan@microsoft.com"

# tools
RUN set -ex \
	&& tools=" \
		gcc \
		make \
		wget \
	" \
	&& apt-get update \
	&& apt-get install -y -V --no-install-recommends $tools \
	&& rm -r /var/lib/apt/lists/*

# apache httpd
ENV HTTPD_VERSION "2.4.25"
ENV HTTPD_DOWNLOAD_URL "https://www.apache.org/dist/httpd/httpd-$HTTPD_VERSION.tar.gz"
ENV HTTPD_SHA1 "377c62dc6b25c9378221111dec87c28f8fe6ac69"
ENV HTTPD_HOME "/usr/local/httpd"
ENV HTTPD_SOURCE "$HTTPD_HOME/src"
ENV HTTPD_CONF_FILE "$HTTPD_HOME/conf/httpd.conf"
ENV HTTPD_CONF_DIR "$HTTPD_HOME/conf"
ENV PATH "$HTTPD_HOME/bin":$PATH
WORKDIR "$HTTPD_HOME"
RUN set -ex \
	&& apt-get update \
	&& apt-get install -y -V --no-install-recommends \
		## runtime deps
		libapr1 \
                libaprutil1 \
                libaprutil1-ldap \
                libapr1-dev \
                libaprutil1-dev \

		## build deps
		libpcre++-dev \
	&& rm -r /var/lib/apt/lists/* \
	
	## download, validate, extract
	&& wget -O httpd.tar.gz "$HTTPD_DOWNLOAD_URL" --no-check-certificate \
	&& echo "$HTTPD_SHA1 *httpd.tar.gz" | sha1sum -c - \
	&& mkdir "$HTTPD_SOURCE" \
	&& tar -xf httpd.tar.gz -C "$HTTPD_SOURCE" --strip-components=1 \
	
	## configure, make, install
	&& cd "$HTTPD_SOURCE" \
	&& ./configure \
		--prefix="$HTTPD_HOME" \
		--enable-mods-shared=reallyall \
	&& make -j "$(nproc)" \
	&& make install \

	## clean up
	&& cd "$HTTPD_HOME" \
	&& rm httpd.tar.gz \
	&& rm -r src man manual \
	&& apt-get purge -y -V -o APT::AutoRemove::RecommendsImportant=false --auto-remove \
		libpcre++-dev \

	## change User, Group
	&& sed -i 's_User daemon_User www-data_' "$HTTPD_CONF_FILE" \
	&& sed -i 's_Group daemon_Group www-data_' "$HTTPD_CONF_FILE" \
	## load rewrite_module
	&& sed -i 's/#LoadModule rewrite_module/LoadModule rewrite_module/' "$HTTPD_CONF_FILE"


# php
## see http://php.net/manual/en/install.unix.apache2.php
## see http://linuxfromscratch.org/blfs/view/svn/general/php.html
ENV PHP_VERSION "7.1.1"
ENV PHP_DOWNLOAD_URL "https://secure.php.net/get/php-7.1.1.tar.gz/from/this/mirror"
ENV PHP_SHA256 "c136279d539c3c2c25176bf149c14913670e79bb27ee6b73e1cd69003985a70d"
ENV PHP_HOME "/usr/local/php"
ENV PHP_SOURCE "$PHP_HOME/src"
ENV PATH "$PHP_HOME/bin":$PATH
WORKDIR $PHP_HOME
RUN set -ex \
	## build deps
	### libbz2-dev >> --with-bz2 >> [phpmyadmin] Bzip2 compression and decompression requires functions (bzopen, bzcompress) which are unavailable on this system.
	### zlib1g-dev >> --with-zlib >> [wordpress] Uncaught Error: Call to undefined function gzinflate() in /var/www/wp-includes/class-requests.php:947
	&& buildDeps=" \
		libbz2-dev \
		libxml2-dev \
		zlib1g-dev \
		" \
	&& apt-get update \
        && apt-get install -y -V --no-install-recommends \	
		## runtime deps
		### libcurl4-gnutls-dev >> --with-curl >> [wordpress] download plugins
		libcurl4-gnutls-dev \
		libxml2 \
		## build deps
		$buildDeps \
	&& rm -rf /var/lib/apt/lists/* \

	## download, validate, extract
	&& wget -O php.tar.gz "$PHP_DOWNLOAD_URL" --no-check-certificate \
	&& echo "$PHP_SHA256 *php.tar.gz" | sha256sum -c - \
	&& mkdir "$PHP_SOURCE" \
	&& tar -xf php.tar.gz -C "$PHP_SOURCE" --strip-components=1 \
	
	## configure, make, install
	&& cd "$PHP_SOURCE" \
	&& ./configure \
		--prefix="$PHP_HOME" \
		--enable-mbstring \
		--enable-zip \
		--with-apxs2="$HTTPD_HOME/bin/apxs" \
		--with-bz2 \
		--with-config-file-path="$PHP_HOME/etc" \
		--with-config-file-scan-dir="$PHP_HOME/etc/conf.d" \
		--with-curl \
		### see http://php.net/manual/en/mysqlnd.overview.php
		### see http://php.net/manual/en/mysqlinfo.api.choosing.php
		--with-mysqli=mysqlnd \
		--with-zlib \
	&& make -j "$(nproc)" \
	&& make install \
	
	## clean up
	&& cd "$PHP_HOME" \
	&& rm php.tar.gz \
	&& rm -r "$PHP_SOURCE" \
	&& apt-get purge -y -V -o APT::AutoRemove::RecommendsImportant=false --auto-remove $buildDeps \

	## include php.conf
	&& echo 'Include conf/php.conf' >> "$HTTPD_CONF_FILE"
COPY php.conf "$HTTPD_CONF_DIR/"


# wordpress
ENV WORDPRESS_VERSION "4.7.2"
ENV WORDPRESS_DOWNLOAD_URL "https://wordpress.org/wordpress-$WORDPRESS_VERSION.tar.gz"
ENV WORDPRESS_SHA1 "7b687f1af589c337124e6247229af209ec1d52c3"
ENV WORDPRESS_HOME "/var/www/wordpress"
WORKDIR "$WORDPRESS_HOME"
RUN set -ex \
	&& wget -O wordpress.tar.gz "$WORDPRESS_DOWNLOAD_URL" --no-check-certificate \
	&& echo "$WORDPRESS_SHA1 *wordpress.tar.gz" | sha1sum -c - \
	&& tar -xf wordpress.tar.gz --strip-components=1 \
	&& rm wordpress.tar.gz \
	&& chown -R www-data:www-data "$WORDPRESS_HOME" \
	
	## include wordpress.conf
        && echo 'Include conf/wordpress.conf' >> "$HTTPD_CONF_FILE"
COPY wordpress.conf "$HTTPD_CONF_DIR/"
COPY wp-config.php.microsoft "$WORDPRESS_HOME/"

# MariaDB
RUN set -ex \
	&& apt-get update \
	&& DEBIAN_FRONTEND=noninteractive apt-get install mariadb-server -y -V --no-install-recommends \
	&& rm -r /var/lib/apt/lists/*


# phpMyAdmin
ENV PHPMYADMIN_VERSION "4.6.6"
ENV PHPMYADMIN_DOWNLOAD_URL "https://files.phpmyadmin.net/phpMyAdmin/$PHPMYADMIN_VERSION/phpMyAdmin-$PHPMYADMIN_VERSION-all-languages.tar.gz"
ENV PHPMYADMIN_SHA256 "54086600558613b31c4daddf4ae58fbc1c252a2b8e3e6fae12f851f78677d72e"
ENV PHPMYADMIN_HOME "/usr/local/phpmyadmin"
WORKDIR $PHPMYADMIN_HOME
RUN set -ex \
	&& wget -O phpmyadmin.tar.gz "$PHPMYADMIN_DOWNLOAD_URL" --no-check-certificate \
	&& echo "$PHPMYADMIN_SHA256 *phpmyadmin.tar.gz" | sha256sum -c - \
	&& tar -xf phpmyadmin.tar.gz -C "$PHPMYADMIN_HOME" --strip-components=1 \
	&& rm phpmyadmin.tar.gz 
COPY config.inc.php "$PHPMYADMIN_HOME"
RUN set -ex \
	&& chown -R www-data:www-data "$PHPMYADMIN_HOME" \
	
	## include phpmyadmin.conf
	&& echo 'Include conf/phpmyadmin.conf' >> "$HTTPD_CONF_FILE"
COPY phpmyadmin.conf "$HTTPD_CONF_DIR/"


# redis
ENV REDIS_VERSION "3.2.8"
ENV REDIS_DOWNLOAD_URL "http://download.redis.io/releases/redis-$REDIS_VERSION.tar.gz"
ENV REDIS_SHA1 "6780d1abb66f33a97aad0edbe020403d0a15b67f"
ENV REDIS_HOME "/usr/local/redis"
ENV REDIS_SOURCE "$REDIS_HOME/src"
ENV PATH "$REDIS_HOME/bin":$PATH
WORKDIR $REDIS_HOME
RUN set -ex \
	&& wget -O redis.tar.gz "$REDIS_DOWNLOAD_URL" --no-check-certificate \
	&& echo "$REDIS_SHA1 *redis.tar.gz" | sha1sum -c - \
	&& mkdir "$REDIS_SOURCE" \
	&& tar -xf redis.tar.gz -C "$REDIS_SOURCE" --strip-components=1 \
	&& cd "$REDIS_SOURCE" \
	&& make \
	&& make PREFIX=/usr/local/redis install \
	&& cd "$REDIS_HOME" \
	&& rm redis.tar.gz \
	&& rm -rf "$REDIS_SOURCE"


# clean up
RUN set -ex \
	&& apt-get purge -y -V -o APT::AutoRemove::RecommendsImportant=false --auto-remove $tools \
	&& apt-get autoremove -y

# 
EXPOSE 80

COPY entrypoint.sh /usr/local/bin/
RUN set -ex \
	&& chmod +x /usr/local/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]

