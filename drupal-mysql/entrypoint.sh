#!/bin/bash

set_var_if_null(){
	local varname="$1"
	if [ ! "${!varname:-}" ]; then
		export "$varname"="$2"
	fi
}

setup_httpd_log_dir(){
	test ! -d "$HTTPD_LOG_DIR" && echo "INFO: $HTTPD_LOG_DIR not found. creating ..." && mkdir -p "$HTTPD_LOG_DIR"
	chown -R www-data:www-data $HTTPD_LOG_DIR
}

setup_mariadb_data_dir(){
	test ! -d "$MARIADB_DATA_DIR" && echo "INFO: $MARIADB_DATA_DIR not found. creating ..." && mkdir -p "$MARIADB_DATA_DIR"

	# check if 'mysql' database exists
	if [ ! -d "$MARIADB_DATA_DIR/mysql" ]; then
		echo "INFO: 'mysql' database doesn't exist under $MARIADB_DATA_DIR. So we think $MARIADB_DATA_DIR is empty."
		echo "Copying all data files from the original folder /var/lib/mysql to $MARIADB_DATA_DIR ..."
		cp -R /var/lib/mysql/. $MARIADB_DATA_DIR
	else
		echo "INFO: 'mysql' database already exists under $MARIADB_DATA_DIR."
	fi

	rm -rf /var/lib/mysql
	ln -s $MARIADB_DATA_DIR /var/lib/mysql

	chown -R mysql:mysql $MARIADB_DATA_DIR
}

setup_mariadb_log_dir(){
	test ! -d "$MARIADB_LOG_DIR" && echo "INFO: $MARIADB_LOG_DIR not found. creating ..." && mkdir -p "$MARIADB_LOG_DIR"
	chown -R mysql:mysql $MARIADB_LOG_DIR
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
	mv $PHPMYADMIN_SOURCE/phpmyadmin-config.inc.php $PHPMYADMIN_HOME/config.inc.php
	rm $PHPMYADMIN_HOME/phpmyadmin.tar.gz
	rm -rf $PHPMYADMIN_SOURCE

	chown -R www-data:www-data $PHPMYADMIN_HOME
}

load_phpmyadmin(){
	if ! grep -q "^Include conf/httpd-phpmyadmin.conf" $HTTPD_CONF_FILE; then
		echo 'Include conf/httpd-phpmyadmin.conf' >> $HTTPD_CONF_FILE
	fi
}

setup_drupal(){
	test ! -d "$DRUPAL_HOME" && echo "INFO: $DRUPAL_HOME not found. creating ..." && mkdir -p "$DRUPAL_HOME"

	cd $DRUPAL_HOME
	mv $DRUPAL_SOURCE/drupal.tar.gz $DRUPAL_HOME/
	tar -xf drupal.tar.gz -C $DRUPAL_HOME/ --strip-components=1
	rm $DRUPAL_HOME/drupal.tar.gz
	rm -rf $DRUPAL_SOURCE

	# create settings.php
	cp $DRUPAL_HOME/sites/default/default.settings.php $DRUPAL_HOME/sites/default/settings.php

	chown -R www-data:www-data $DRUPAL_HOME
}

update_settings(){
	set_var_if_null "DRUPAL_DB_HOST" "localhost"
	set_var_if_null "DRUPAL_DB_NAME" "drupal"
	set_var_if_null "DRUPAL_DB_USERNAME" "drupal"
	set_var_if_null "DRUPAL_DB_PASSWORD" "MS173m_QN"
	if [ "${DRUPAL_DB_HOST,,}" = "localhost" -o "$DRUPAL_DB_HOST" = "127.0.0.1" ]; then
		export DRUPAL_DB_HOST="localhost"
	fi

	echo "#do not remove/uncomment the following line." >> $DRUPAL_HOME/sites/default/settings.php
	echo "#docker: DRUPAL_DB_HOST=$DRUPAL_DB_HOST" >> $DRUPAL_HOME/sites/default/settings.php
}

load_drupal(){
	if ! grep -q "^Include conf/httpd-drupal.conf" $HTTPD_CONF_FILE; then
		echo 'Include conf/httpd-drupal.conf' >> $HTTPD_CONF_FILE
	fi
}

set -e

echo "INFO: DRUPAL_DB_HOST:" $DRUPAL_DB_HOST
echo "INFO: DRUPAL_DB_NAME:" $DRUPAL_DB_NAME
echo "INFO: DRUPAL_DB_USERNAME:" $DRUPAL_DB_USERNAME
echo "INFO: PHPMYADMIN_USERNAME:" $PHPMYADMIN_USERNAME

setup_httpd_log_dir
apachectl start

# That settings.php doesn't exist means Drupal is not installed/configured yet.
if [ ! -e "$DRUPAL_HOME/sites/default/settings.php" ]; then
	echo "INFO: $DRUPAL_HOME/sites/default/settings.php not found."
	echo "Installing Drupal for the first time ..."
	setup_drupal
	update_settings
else
	echo "INFO: $DRUPAL_HOME/sites/default/settings.php already exists."
fi

# If local MariaDB is used in settings.php
if grep -q "^#docker: DRUPAL_DB_HOST=localhost\|^#docker: DRUPAL_DB_HOST=127.0.0.1" "$DRUPAL_HOME/sites/default/settings.php"; then
	echo "INFO: local MariaDB is used as DB_HOST in settings.php."
	echo "Setting up MariaDB data dir ..."
	setup_mariadb_data_dir
	echo "Setting up MariaDB log dir ..."
	setup_mariadb_log_dir
	echo "Starting local MariaDB ..."
	start_mariadb

	echo "Granting user for phpMyAdmin ..."
	set_var_if_null 'PHPMYADMIN_USERNAME' 'phpmyadmin'
	set_var_if_null 'PHPMYADMIN_PASSWORD' 'MS173m_QN'
	mysql -u root -e "GRANT ALL ON *.* TO \`$PHPMYADMIN_USERNAME\`@'localhost' IDENTIFIED BY '$PHPMYADMIN_PASSWORD' WITH GRANT OPTION; FLUSH PRIVILEGES;"

	echo "Creating database for Drupal if not exists ..."
	mysql -u root -e "CREATE DATABASE IF NOT EXISTS \`$DRUPAL_DB_NAME\` CHARACTER SET utf8 COLLATE utf8_general_ci;"
	echo "Granting user for Drupal ..."
	mysql -u root -e "GRANT ALL ON \`$DRUPAL_DB_NAME\`.* TO \`$DRUPAL_DB_USERNAME\`@\`$DRUPAL_DB_HOST\` IDENTIFIED BY '$DRUPAL_DB_PASSWORD'; FLUSH PRIVILEGES;"

	if [ ! -e "$PHPMYADMIN_HOME/config.inc.php" ]; then
		echo "INFO: $PHPMYADMIN_HOME/config.inc.php not found."
		echo "Installing phpMyAdmin ..."
		setup_phpmyadmin
        else
		echo "INFO: $PHPMYADMIN_HOME/config.inc.php already exists."
	fi

	echo "Loading phpMyAdmin conf ..."
	load_phpmyadmin
else
	echo "INFO: local MariaDB is NOT used as DB_HOST in settings.php."
fi

apachectl stop
# delay 2 seconds to try to avoid "httpd (pid XX) already running"
sleep 2s

echo "Loading Drupal conf ..."
load_drupal

echo "Starting Apache httpd -D FOREGROUND ..."
apachectl start -D FOREGROUND
