#!/bin/bash
log(){
	while read line ; do
		echo "`date '+%D %T'` $line"
	done
}

set -e
logfile=/home/LogFiles/entrypoint.log
test ! -f $logfile && mkdir -p /home/LogFiles && touch $logfile
exec > >(log | tee -ai $logfile)
exec 2>&1

set_var_if_null(){
	local varname="$1"
	if [ ! "${!varname:-}" ]; then
		export "$varname"="$2"
	fi
}

# setup nginx log dir
test ! -d "$NGINX_LOG_DIR" && echo "INFO: $NGINX_LOG_DIR not found, creating ..." && mkdir -p "$NGINX_LOG_DIR"

# setup uWSGI ini dir
test ! -d "$UWSGI_INI_DIR" && echo "INFO: $UWSGI_INI_DIR not found, creating ..." && mkdir -p "$UWSGI_INI_DIR"

# setup django project home dir
test ! -d "$DJANGO_PROJECT_HOME" && echo "INFO: $DJANGO_PROJECT_HOME not found, creating ..." && mkdir -p $DJANGO_PROJECT_HOME
WSGI_PY_PATH=`find $DJANGO_PROJECT_HOME -name wsgi.py`
if [ "$WSGI_PY_PATH" ]; then
	echo "INFO: wsgi.py found at $WSGI_PY_PATH. So we think a django project already exists under $DJANGO_PROJECT_HOME."
else
	# create a sample django project
	echo "INFO: creating sample django project 'myproject' under $DJANGO_PROJECT_HOME ..."
	django-admin startproject myproject "$DJANGO_PROJECT_HOME"
	echo "INFO: set ALLOWED_HOSTS = ['*'] in settings.py to eliminate DisallowedHost warning. "
	sed -i "s/ALLOWED_HOSTS = \[\]/ALLOWED_HOSTS = \['\*'\]/" "$DJANGO_PROJECT_HOME/myproject/settings.py"
	mv /tmp/uwsgi.ini "$UWSGI_INI_DIR/"
fi

chown -R www-data:www-data "$NGINX_LOG_DIR"
chown -R www-data:www-data "$UWSGI_INI_DIR"
chown -R www-data:www-data "$DJANGO_PROJECT_HOME"

echo "INFO: creating /tmp/uwsgi.sock ..."
rm -f /tmp/uwsgi.sock
touch /tmp/uwsgi.sock
chown www-data:www-data /tmp/uwsgi.sock
chmod 664 /tmp/uwsgi.sock

echo "INFO: starting nginx ..."
nginx #-g "daemon off;"

echo "INFO: starting uwsgi ..."
uwsgi --uid www-data --gid www-data --ini=$UWSGI_INI_DIR/uwsgi.ini

