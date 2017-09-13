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

update_settings(){
	set_var_if_null "DATABASE_TYPE" "remote"
	set_var_if_null 'PHPMYADMIN_USERNAME' 'phpmyadmin'
	set_var_if_null 'PHPMYADMIN_PASSWORD' 'MS173m_QN'
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

	echo "INFO: loading local MariaDB and phpMyAdmin ..."
	echo "INFO: DATABASE_TYPE:" $DATABASE_TYPE
	echo "INFO: PHPMYADMIN_USERNAME:" $PHPMYADMIN_USERNAME

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
		mysql -u root -e "GRANT ALL ON *.* TO \`$PHPMYADMIN_USERNAME\`@'localhost' IDENTIFIED BY '$PHPMYADMIN_PASSWORD' WITH GRANT OPTION; FLUSH PRIVILEGES;"
		echo "Installing phpMyAdmin ..."
		setup_phpmyadmin
	else
		echo "INFO: $PHPMYADMIN_HOME/config.inc.php already exists."
	fi

	echo "Loading phpMyAdmin conf ..."
	if ! grep -q "^Include conf/httpd-phpmyadmin.conf" $HTTPD_CONF_FILE; then
		echo 'Include conf/httpd-phpmyadmin.conf' >> $HTTPD_CONF_FILE
	fi
fi

apachectl stop
# delay 2 seconds to try to avoid "httpd (pid XX) already running"
sleep 2s

echo "Starting Apache httpd -D FOREGROUND ..."
apachectl start -D FOREGROUND
