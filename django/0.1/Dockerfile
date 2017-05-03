#
# Dockerfile for Django
#
FROM ubuntu:16.04
MAINTAINER Azure App Service Container Images <appsvc-images@microsoft.com>


# ========
# ENV vars
# ========

# nginx
ENV NGINX_LOG_DIR "/home/LogFiles/nginx"
# uwsgi
ENV UWSGI_INI_DIR "/home/uwsgi"
# django
ENV DJANGO_PROJECT_HOME "/home/site/wwwroot"
#
ENV DOCKER_BUILD_HOME "/dockerbuild"


# =======
# Install
# =======

WORKDIR $DOCKER_BUILD_HOME

RUN set -ex \
	# tools
	&& tools=' \
		gcc \
		wget \
	' \
	&& apt-get update \
        && apt-get install -y -V --no-install-recommends $tools \
        && rm -r /var/lib/apt/lists/* \

	# nginx
	&& apt-get update \
	&& apt-get install -y -V --no-install-recommends nginx \
	&& rm -r /var/lib/apt/lists/* \

	# python
	&& apt-get update \
	&& apt-get install -y -V --no-install-recommends python3 python3-dev \
	&& rm -r /var/lib/apt/lists/* \

	# django
	&& wget https://bootstrap.pypa.io/get-pip.py --no-check-certificate \
	&& python3 get-pip.py \
	&& pip install psycopg2 \
	## see https://docs.djangoproject.com/en/1.7/howto/deployment/wsgi/uwsgi/
	&& pip install http://projects.unbit.it/downloads/uwsgi-lts.tar.gz \
	&& pip install django \

	# clean up
	&& apt-get purge -y -V -o APT::AutoRemove::RecommendsImportant=false --auto-remove $tools \
	&& apt-get autoremove -y


# =========
# Configure
# =========

COPY nginx-default-site /etc/nginx/sites-available/default
COPY uwsgi.ini /tmp/ 

RUN set -ex \
	&& ln -s /usr/bin/python3 /usr/bin/python \
	##
        && rm -rf /var/log/nginx \
        && ln -s $NGINX_LOG_DIR /var/log/nginx \
	##
	&& rm -rf /var/www/html \
	&& ln -s $DJANGO_PROJECT_HOME /var/www/default \
	##
	&& rm -rf $DOCKER_BUILD_HOME/*


COPY entrypoint.sh /usr/local/bin
RUN chmod u+x /usr/local/bin/entrypoint.sh
EXPOSE 80
ENTRYPOINT ["entrypoint.sh"]
