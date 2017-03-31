#
# Dockerfile for Magento CE
#
FROM ubuntu:16.04
MAINTAINER Azure App Service Container Images <appsvc-images@microsoft.com>


# ========
# ENV vars
# ========

# apache httpd
ENV HTTPD_VERSION "2.4.25"
ENV HTTPD_DOWNLOAD_URL "https://www.apache.org/dist/httpd/httpd-$HTTPD_VERSION.tar.gz"
ENV HTTPD_SHA1 "377c62dc6b25c9378221111dec87c28f8fe6ac69"
ENV HTTPD_SOURCE "/usr/src/httpd"
ENV HTTPD_HOME "/usr/local/httpd"
ENV HTTPD_CONF_DIR "$HTTPD_HOME/conf"
ENV HTTPD_CONF_FILE "$HTTPD_CONF_DIR/httpd.conf"
ENV HTTPD_LOG_DIR="/var/log/httpd"
ENV PATH "$HTTPD_HOME/bin":$PATH

# php
### see http://devdocs.magento.com/guides/v2.1/install-gde/prereq/php-ubuntu.html#php-support
ENV PHP_VERSION "7.0.16"
ENV PHP_DOWNLOAD_URL "https://secure.php.net/get/php-$PHP_VERSION.tar.gz/from/this/mirror"
ENV PHP_SHA256 "bc6709dc7612957d0533c09c9c8a9c2e7c4fd9d64e697707bb1b39670eab61d4"
ENV PHP_SOURCE "/usr/src/php"
ENV PHP_HOME "/usr/local/php"
ENV PHP_CONF_DIR "$PHP_HOME/etc"
ENV PHP_CONF_DIR_SCAN "$PHP_CONF_DIR/conf.d"
ENV PATH "$PHP_HOME/bin":$PATH

# mariadb
ENV MARIADB_DATA_DIR="/var/lib/mysql"
ENV MARIADB_LOG_DIR="/var/log/mysql"
ENV MARIADB_DATA_DIR_TEMP="/tmp/mariadb"

# redis
ENV REDIS_VERSION "3.2.8"
ENV REDIS_DOWNLOAD_URL "http://download.redis.io/releases/redis-$REDIS_VERSION.tar.gz"
ENV REDIS_SHA1 "6780d1abb66f33a97aad0edbe020403d0a15b67f"
ENV REDIS_SOURCE "/usr/src/redis"
ENV REDIS_HOME "/usr/local/redis"
ENV PATH "$REDIS_HOME/bin":$PATH

# magento ce
ENV MAGENTO_VERSION "2.1.5"
ENV MAGENTO_PACKAGE "Magento-CE-$MAGENTO_VERSION.tar.gz"
ENV MAGENTO_SOURCE "/usr/src/magento"
ENV MAGENTO_HOME "/var/www/magento"
ENV PATH "$MAGENTO_HOME/bin":$PATH

# phpMyAdmin
ENV PHPMYADMIN_VERSION "4.6.6"
ENV PHPMYADMIN_DOWNLOAD_URL "https://files.phpmyadmin.net/phpMyAdmin/$PHPMYADMIN_VERSION/phpMyAdmin-$PHPMYADMIN_VERSION-all-languages.tar.gz"
ENV PHPMYADMIN_SHA256 "54086600558613b31c4daddf4ae58fbc1c252a2b8e3e6fae12f851f78677d72e"
ENV PHPMYADMIN_SOURCE "/usr/src/phpmyadmin"
ENV PHPMYADMIN_HOME "/var/www/phpmyadmin"

ENV DOCKER_BUILD_HOME "/dockerbuild"


# ====================
# Download and Install
# 1. tools
# 2. apache httpd
# 3. php
# 4. mariadb
# 5. redis
# 6. magento ce
# 7. phpmyadmin
# 8. cron
# ====================

WORKDIR $DOCKER_BUILD_HOME
COPY $MAGENTO_PACKAGE $DOCKER_BUILD_HOME/
RUN set -ex \
	# ------------------
	# 1. tools
	# ------------------
	&& tools=" \
		g++ \
		gcc \
		make \
		pkg-config \
		wget \
	" \
	&& apt-get update \
	&& apt-get install -y -V --no-install-recommends $tools \
	&& rm -r /var/lib/apt/lists/* \

	# ---------------
	# 2. apache httpd
	# ---------------
	&& mkdir -p $HTTPD_SOURCE \
	&& mkdir -p $HTTPD_HOME \
	## runtime and buildtime deps
	&& httpdBuildtimeDeps=" \
		libpcre++-dev \
		libssl-dev \
	" \
	&& httpdRuntimeDeps="\
		libapr1 \
		libaprutil1 \
		libaprutil1-ldap \
		libapr1-dev \
		libaprutil1-dev \
	" \
	&& apt-get update \
	&& apt-get install -y -V --no-install-recommends $httpdBuildtimeDeps $httpdRuntimeDeps \		
	&& rm -r /var/lib/apt/lists/* \
	## download, validate, extract
	&& cd $DOCKER_BUILD_HOME \
	&& wget -O httpd.tar.gz "$HTTPD_DOWNLOAD_URL" --no-check-certificate \
	&& echo "$HTTPD_SHA1 *httpd.tar.gz" | sha1sum -c - \
	&& tar -xf httpd.tar.gz -C $HTTPD_SOURCE --strip-components=1 \
	## configure, make, install
	&& cd $HTTPD_SOURCE \
	&& ./configure \
		--prefix=$HTTPD_HOME \
		### using prefork for PHP. see http://php.net/manual/en/install.unix.apache2.php
		--with-mpm=prefork \
		--enable-mods-shared=reallyall \
		--enable-ssl \
	&& make -j "$(nproc)" \
	&& make install \
	## clean up
	&& rm -rf $HTTPD_SOURCE \
		$HTTPD_HOME/man \
		$HTTPD_HOME/manual \
	&& rm $DOCKER_BUILD_HOME/httpd.tar.gz \
	&& apt-get purge -y -V -o APT::AutoRemove::RecommendsImportant=false --auto-remove $httpdBuildtimeDeps \

	# ------
	# 3. php
	# ------
	### see http://php.net/manual/en/install.unix.apache2.php
	### see http://linuxfromscratch.org/blfs/view/svn/general/php.html
	&& mkdir -p $PHP_SOURCE \
	&& mkdir -p $PHP_HOME \
	## buildtime deps
	&& phpBuildtimeDeps="\
		libbz2-dev \
		libgmp-dev \
        libicu-dev \
		libjpeg-dev \
		libpng12-dev \
		libldap2-dev \
		libmcrypt-dev \
		libmhash-dev \
		libssl-dev \
		libxml2-dev \
		libxslt-dev \
	" \
	## runtime deps
	&& phpRuntimeDeps=" \
		libcurl4-openssl-dev \
		libjpeg8 \
        libpng12-0 \
		libmcrypt4 \
		libxml2 \
		libxslt1.1 \
	" \
	&& apt-get update \
	&& apt-get install -y -V --no-install-recommends $phpBuildtimeDeps $phpRuntimeDeps \	
	&& rm -rf /var/lib/apt/lists/* \
	&& ln -s /usr/include/x86_64-linux-gnu/gmp.h /usr/include/gmp.h \
	&& ln -s /usr/lib/x86_64-linux-gnu/libldap.so /usr/lib/libldap.so \
	&& ln -s /usr/lib/x86_64-linux-gnu/liblber.so /usr/lib/liblber.so \
	## download, validate, extract
	&& cd $DOCKER_BUILD_HOME \
	&& wget -O php.tar.gz "$PHP_DOWNLOAD_URL" --no-check-certificate \
	&& echo "$PHP_SHA256 *php.tar.gz" | sha256sum -c - \
	&& tar -xf php.tar.gz -C $PHP_SOURCE --strip-components=1 \	
	## configure, make, install
	&& cd $PHP_SOURCE \
	&& ./configure \
		--prefix=$PHP_HOME \
		### we don't need CGI version of PHP here
		--disable-cgi \
		--enable-bcmath \
		--enable-intl \
		--enable-mbstring \
		--enable-soap \
		--enable-zip \
		--with-apxs2=$HTTPD_HOME/bin/apxs \
		--with-bz2 \
		--with-config-file-path=$PHP_CONF_DIR \
		--with-config-file-scan-dir=$PHP_CONF_DIR_SCAN \
		--with-curl \
		--with-gd \
		--with-jpeg-dir \
		--with-png-dir \
		--with-gmp \
		--with-ldap \
		--with-mcrypt \
		--with-mhash \
		### for phpmyadmin
		--with-mysqli=mysqlnd \
		--with-openssl \
		### see http://php.net/manual/en/mysqlinfo.library.choosing.php
		--with-pdo-mysql=mysqlnd \
		--with-xsl \
	&& make -j "$(nproc)" \
	&& make install \	
	## clean up
	&& rm -rf $PHP_SOURCE \
	&& rm -rf $PHP_HOME/php/man \
	&& rm $DOCKER_BUILD_HOME/php.tar.gz \
	&& apt-get purge -y -V -o APT::AutoRemove::RecommendsImportant=false --auto-remove $phpBuildtimeDeps \

	# ----------
	# 4. mariadb
	# ----------
	&& apt-get update \
	&& DEBIAN_FRONTEND=noninteractive apt-get install mariadb-server -y -V --no-install-recommends \
	&& rm -r /var/lib/apt/lists/* \

	# --------
	# 5. redis
	# --------
	&& mkdir -p $REDIS_SOURCE \
	&& mkdir -p $REDIS_HOME \
	&& cd $DOCKER_BUILD_HOME \
	&& wget -O redis.tar.gz "$REDIS_DOWNLOAD_URL" --no-check-certificate \
	&& echo "$REDIS_SHA1 *redis.tar.gz" | sha1sum -c - \
	&& tar -xf redis.tar.gz -C $REDIS_SOURCE --strip-components=1 \
	&& cd $REDIS_SOURCE \
	&& make -j "$(nproc)" \
	&& make PREFIX=$REDIS_HOME install \
	&& rm -rf $REDIS_SOURCE \
	&& rm $DOCKER_BUILD_HOME/redis.tar.gz \

	# ------------	
	# 6. magento ce
	# ------------
	&& mkdir -p $MAGENTO_SOURCE \
	&& cd $DOCKER_BUILD_HOME \
	&& tar -xf $MAGENTO_PACKAGE -C $MAGENTO_SOURCE \
	&& rm $DOCKER_BUILD_HOME/$MAGENTO_PACKAGE \

	# -------------
	# 7. phpmyadmin
	# -------------
	&& mkdir -p $PHPMYADMIN_SOURCE \
	&& cd $DOCKER_BUILD_HOME \
	&& wget -O phpmyadmin.tar.gz "$PHPMYADMIN_DOWNLOAD_URL" --no-check-certificate \
	&& echo "$PHPMYADMIN_SHA256 *phpmyadmin.tar.gz" | sha256sum -c - \
	&& tar -xf phpmyadmin.tar.gz -C $PHPMYADMIN_SOURCE --strip-components=1 \
	&& rm $DOCKER_BUILD_HOME/phpmyadmin.tar.gz \

	# -------
	# 8. cron
	# -------
	&& apt-get update \
	&& apt-get install cron -y -V --no-install-recommends \
	&& rm -r /var/lib/apt/lists/* \

	# ----------
	# ~. clean up
	# ----------
	&& apt-get purge -y -V -o APT::AutoRemove::RecommendsImportant=false --auto-remove $tools \
	&& apt-get autoremove -y	


# ==============
# Configurations 
# ==============

# httpd confs
COPY httpd.conf $HTTPD_CONF_DIR/
COPY httpd-modules.conf $HTTPD_CONF_DIR/
COPY httpd-php.conf $HTTPD_CONF_DIR/
COPY httpd-magento.conf $HTTPD_CONF_DIR/
COPY httpd-phpmyadmin.conf $HTTPD_CONF_DIR/
# php confs
COPY php.ini $PHP_CONF_DIR/
COPY php-log.ini $PHP_CONF_DIR_SCAN/
COPY php-opcache.ini $PHP_CONF_DIR_SCAN/
# phpmyadmin config
COPY phpmyadmin-config.inc.php $PHPMYADMIN_SOURCE/config.inc.php
RUN set -ex \
	&& echo 'Include conf/httpd-php.conf' >> $HTTPD_CONF_FILE \
	&& test ! -d /var/lib/php/sessions && mkdir -p /var/lib/php/sessions \
	&& chown www-data:www-data /var/lib/php/sessions


# =====================================
# Azure Web App on Linux configurations
# =====================================
# /home is a shared directory among multiple web app instances
# /home/site/wwwroot for Magento site
# /home/phpmyadmin for phpMyAdmin site
# /home/data for native MariaDB data dir
# /home/LogFiles/httpd for httpd/php/magento/phpmyadmin logs
# /home/LogFiles/mariadb for mariadb logs

ENV AZURE_SITE_ROOT "/home/site/wwwroot"
ENV PHPMYADMIN_HOME_AZURE "/home/phpmyadmin"
ENV MARIADB_DATA_DIR_AZURE "/home/data"
ENV HTTPD_LOG_DIR_AZURE "/home/LogFiles/httpd"
ENV MARIADB_LOG_DIR_AZURE "/home/LogFiles/mariadb"


# =====
# final
# =====
COPY entrypoint.sh /usr/local/bin/
RUN set -ex \
	&& chmod +x /usr/local/bin/entrypoint.sh \
	&& test ! -d /var/www && mkdir -p /var/www \
	&& echo '<html><head><meta http-equiv="refresh" content="15" /><title>Installing Magento ...</title></head><body>Installing Magento ... This could be done in minutes. But it will take longer if running on Azure Web App for Linux.</body></html>' > /var/www/index.html \
	&& chown -R www-data:www-data /var/www \
	&& chmod 664 /var/www/index.html	
EXPOSE 80
ENTRYPOINT ["entrypoint.sh"]

