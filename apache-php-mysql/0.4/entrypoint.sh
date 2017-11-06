#!/bin/bash

set_var_if_null(){
	local varname="$1"
	if [ ! "${!varname:-}" ]; then
		export "$varname"="$2"
	fi
}

setup_mariadb_data_dir(){
	test ! -d "$MARIADB_DATA_DIR" && echo "INFO: $MARIADB_DATA_DIR not found. creating ..." && mkdir -p "$MARIADB_DATA_DIR"

	# check if 'mysql' database exists
	if [ ! -d "$MARIADB_DATA_DIR/mysql" ]; then
		echo "INFO: 'mysql' database doesn't exist under $MARIADB_DATA_DIR. So we think $MARIADB_DATA_DIR is empty."
		echo "Copying all data files from the original folder /var/lib/mysql to $MARIADB_DATA_DIR ..."
		cp -R --no-clobber /var/lib/mysql/. $MARIADB_DATA_DIR
	else
		echo "INFO: 'mysql' database already exists under $MARIADB_DATA_DIR."
	fi

	rm -rf /var/lib/mysql
	ln -s $MARIADB_DATA_DIR /var/lib/mysql

	chown -R mysql:mysql $MARIADB_DATA_DIR
}

start_mariadb(){
	service mysql start
	rm -f /tmp/mysql.sock
	ln -s /var/run/mysqld/mysqld.sock /tmp/mysql.sock

	# create default database 'azurelocaldb'
	mysql -u root -e "CREATE DATABASE IF NOT EXISTS azurelocaldb; FLUSH PRIVILEGES;"
}

setup_phpmyadmin(){
	test ! -d "$PHPMYADMIN_HOME" && echo "INFO: $PHPMYADMIN_HOME not found. creating ..." && mkdir -p "$PHPMYADMIN_HOME"

	cd $PHPMYADMIN_HOME
	mv $PHPMYADMIN_SOURCE/phpmyadmin.tar.gz $PHPMYADMIN_HOME/
	tar -xf phpmyadmin.tar.gz -C $PHPMYADMIN_HOME --strip-components=1
	# create config.inc.php
	cp -R --no-clobber $PHPMYADMIN_SOURCE/phpmyadmin-config.inc.php $PHPMYADMIN_HOME/config.inc.php
	rm $PHPMYADMIN_HOME/phpmyadmin.tar.gz
	rm -rf $PHPMYADMIN_SOURCE

	chown -R www-data:www-data $PHPMYADMIN_HOME
}

setup_localdb(){
	echo "INFO: loading local MariaDB and phpMyAdmin ..."
	echo "INFO: DATABASE_TYPE:" $DATABASE_TYPE
	echo "INFO: DATABASE_USERNAME:" $DATABASE_USERNAME

	# local MariaDB is used
	echo "Setting up MariaDB data dir ..."
	setup_mariadb_data_dir
	echo "Setting up MariaDB log dir ..."
	test ! -d "$MARIADB_LOG_DIR" && echo "INFO: $MARIADB_LOG_DIR not found. creating ..." && mkdir -p "$MARIADB_LOG_DIR"
	chown -R mysql:mysql $MARIADB_LOG_DIR
	echo "Starting local MariaDB ..."
	start_mariadb

	if [ ! -e "$PHPMYADMIN_HOME/config.inc.php" ]; then
		echo "INFO: $PHPMYADMIN_HOME/config.inc.php not found."
		echo "Granting user for phpMyAdmin ..."
		mysql -u root -e "GRANT ALL ON *.* TO \`$DATABASE_USERNAME\`@'localhost' IDENTIFIED BY '$DATABASE_PASSWORD' WITH GRANT OPTION; FLUSH PRIVILEGES;"
		echo "Installing phpMyAdmin ..."
		setup_phpmyadmin
	else
		echo "INFO: $PHPMYADMIN_HOME/config.inc.php already exists."
	fi

	echo "Loading phpMyAdmin conf ..."
	if ! grep -q "^Include conf/httpd-phpmyadmin.conf" $HTTPD_CONF_FILE; then
		echo 'Include conf/httpd-phpmyadmin.conf' >> $HTTPD_CONF_FILE
	fi
}

update_settings(){
	set_var_if_null "DATABASE_TYPE" "remote"
	set_var_if_null "LOCALDB_ERROR" "hostingstart.htm"
}

set -e

echo "Starting SSH ..."
service ssh start

test ! -d "$APP_HOME" && echo "INFO: $APP_HOME not found. creating ..." && mkdir -p "$APP_HOME"
chown -R www-data:www-data $APP_HOME

test ! -d "$HTTPD_LOG_DIR" && echo "INFO: $HTTPD_LOG_DIR not found. creating ..." && mkdir -p "$HTTPD_LOG_DIR"
chown -R www-data:www-data $HTTPD_LOG_DIR
apachectl start

update_settings

if [ "${DATABASE_TYPE,,}" = "local" ]; then
	# Phpmyadmin Log Info. Details please find: Version 0.4 - 3
	if [ -z $DATABASE_PASSWORD ]; then
		echo "MariaDB Error: Please set var DATABASE_PASSWORD on App settings"
		echo '<!DOCTYPE html><html><head><title> MariaDB Error </title></head><body><font color =\"#aa0000\"><h2>MariaDB Error.</h2></font>' > $APP_HOME/$LOCALDB_ERROR
		echo 'Fail to enable Local Database. Please set DATABASE_PASSWORD on App settings.</body></html>' >> $APP_HOME/$LOCALDB_ERROR
	fi

	if [ -z $DATABASE_USERNAME ]; then
		echo "MariaDB Error: Please set var DATABASE_USERNAME on App settings"
		echo '<!DOCTYPE html><html><head><title> MariaDB Error </title></head><body><font color =\"#aa0000\"><h2>MariaDB Error.</h2></font>' > $APP_HOME/$LOCALDB_ERROR
		echo 'Fail to enable Local Database. Please set DATABASE_USERNAME/DATABASE_PASSWORD on App settings.</body></html>' >> $APP_HOME/$LOCALDB_ERROR
	fi

	if [ ! -z $DATABASE_USERNAME ] && [ ! -z $DATABASE_PASSWORD ]; then
		setup_localdb

		if [ -e $APP_HOME/$LOCALDB_ERROR ]; then
			rm -f $APP_HOME/$LOCALDB_ERROR
		fi
	fi
else
	# ensure app install without effect of LOCALDB_ERROR if not local mode
	if [ -e $APP_HOME/$LOCALDB_ERROR ]; then
		rm -f $APP_HOME/$LOCALDB_ERROR
	fi
fi

apachectl stop
# delay 2 seconds to try to avoid "httpd (pid XX) already running"
sleep 2s

echo "Starting Apache httpd -D FOREGROUND ..."
apachectl start -D FOREGROUND
