#
# Dockerfile for Apache-PHP-PostgreSQL
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
ENV HTTPD_LOG_DIR="/home/LogFiles/httpd"
ENV PATH "$HTTPD_HOME/bin":$PATH

# php
ENV PHP_VERSION "7.1.2"
ENV PHP_DOWNLOAD_URL "https://secure.php.net/get/php-$PHP_VERSION.tar.gz/from/this/mirror"
ENV PHP_SHA256 "e6773217c9c719ca22abb104ae3d437d53daceaf31faf2e5eeb1f9f5028005d8"
ENV PHP_SOURCE "/usr/src/php"
ENV PHP_HOME "/usr/local/php"
ENV PHP_CONF_DIR "$PHP_HOME/etc"
ENV PHP_CONF_DIR_SCAN "$PHP_CONF_DIR/conf.d"
ENV PATH "$PHP_HOME/bin":$PATH

# ssh
ENV SSH_PASSWD "root:Docker!"

# app
ENV APP_HOME "/home/site/wwwroot"
#
ENV DOCKER_BUILD_HOME "/dockerbuild"


# ====================
# Download and Install
# ~. tools
# 1. essentials
# 2. apache httpd
# 3. php
# 4. ssh
# ====================

WORKDIR $DOCKER_BUILD_HOME
RUN set -ex \
	# --------
	# ~. tools
	# --------
	&& tools=" \
		g++ \
		gcc \
		make \
		pkg-config \
		wget \
		vim \
	" \
	&& apt-get update \
	&& apt-get install -y -V --no-install-recommends $tools \
	&& rm -r /var/lib/apt/lists/* \

	# -------------
	# 1. essentials
	# -------------
	&& essentials=" \
		ca-certificates \
	" \
	&& apt-get update \
	&& apt-get install -y -V --no-install-recommends $essentials \
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
	&& make clean \
	## clean up
	&& rm -rf $HTTPD_SOURCE \
		$HTTPD_HOME/man \
		$HTTPD_HOME/manual \
	&& rm $DOCKER_BUILD_HOME/httpd.tar.gz \
	&& apt-get purge -y -V -o APT::AutoRemove::RecommendsImportant=false --auto-remove $httpdBuildtimeDeps \

	# ------
	# 3. php
	# ------
	&& apt-get update \
	&& apt-get install -y -V --no-install-recommends postgresql \
	&& rm -r /var/lib/apt/lists/* \
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
		libpq-dev \
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
	#&& rm -rf /var/lib/apt/lists/* \
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
		--enable-ftp \
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
		--with-openssl \
		--with-xsl \
		--with-zlib \
		--with-pgsql \
		--with-pdo-pgsql \
	&& make -j "$(nproc)" \
	&& make install \
	&& make clean \
	## clean up
	&& rm -rf $PHP_SOURCE \
	&& rm -rf $PHP_HOME/php/man \
	&& rm $DOCKER_BUILD_HOME/php.tar.gz \
	&& apt-get purge -y -V -o APT::AutoRemove::RecommendsImportant=false --auto-remove $phpBuildtimeDeps \
	
	# ------
	# 4. ssh
	# ------
	&& apt-get update \
	&& apt-get install -y --no-install-recommends openssh-server \
	&& echo "$SSH_PASSWD" | chpasswd \
	
	# -----------
	# ~. clean up
	# -----------
	&& apt-get purge -y -V -o APT::AutoRemove::RecommendsImportant=false --auto-remove $tools \
	&& apt-get autoremove -y	


# =========
# Configure
# =========

# httpd
COPY httpd.conf $HTTPD_CONF_DIR/
COPY httpd-modules.conf $HTTPD_CONF_DIR/
COPY httpd-php.conf $HTTPD_CONF_DIR/
# php
COPY php.ini $PHP_CONF_DIR/
COPY php-opcache.ini $PHP_CONF_DIR_SCAN/
# ssh
COPY sshd_config /etc/ssh/

RUN set -ex \
	&& echo 'Include conf/httpd-php.conf' >> $HTTPD_CONF_FILE \
	&& test ! -d /var/lib/php/sessions && mkdir -p /var/lib/php/sessions \
	&& chown www-data:www-data /var/lib/php/sessions \
	##
	&& test ! -d /var/www && mkdir -p /var/www \
        && chown -R www-data:www-data /var/www \
	##
	&& rm -rf /var/log/httpd \
	&& ln -s $HTTPD_LOG_DIR /var/log/httpd \
	##
	&& ln -s $APP_HOME /var/www

# =====
# final
# =====
COPY entrypoint.sh /usr/local/bin/
RUN chmod u+x /usr/local/bin/entrypoint.sh
EXPOSE 2222 80
ENTRYPOINT ["entrypoint.sh"]
