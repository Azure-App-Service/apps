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

setup_wordpress(){
	test ! -d "$WORDPRESS_HOME" && echo "INFO: $WORDPRESS_HOME not found. creating ..." && mkdir -p "$WORDPRESS_HOME"

	cd $WORDPRESS_HOME
	mv $WORDPRESS_SOURCE/wordpress.tar.gz $WORDPRESS_HOME/
	tar -xf wordpress.tar.gz -C $WORDPRESS_HOME/ --strip-components=1
	# create wp-config.php
	mv $WORDPRESS_SOURCE/wp-config.php.microsoft $WORDPRESS_HOME/wp-config.php

	rm $WORDPRESS_HOME/wordpress.tar.gz
	rm -rf $WORDPRESS_SOURCE

	chown -R www-data:www-data $WORDPRESS_HOME 
}

update_wordpress_config(){
	set_var_if_null "DATABASE_HOST" "localhost"
	set_var_if_null "DATABASE_NAME" "wordpress"
	set_var_if_null "DATABASE_USERNAME" "wordpress"
	set_var_if_null "DATABASE_PASSWORD" "MS173m_QN"
	set_var_if_null "TABLE_NAME_PREFIX" "wp_"
	if [ "${DATABASE_HOST,,}" = "localhost" ]; then
		export DATABASE_HOST="localhost"
	fi

	# update wp-config.php with the vars
        sed -i "s/connectstr_dbhost = '';/connectstr_dbhost = '$DATABASE_HOST';/" "$WORDPRESS_HOME/wp-config.php"
        sed -i "s/connectstr_dbname = '';/connectstr_dbname = '$DATABASE_NAME';/" "$WORDPRESS_HOME/wp-config.php"
        sed -i "s/connectstr_dbusername = '';/connectstr_dbusername = '$DATABASE_USERNAME';/" "$WORDPRESS_HOME/wp-config.php"
        sed -i "s/connectstr_dbpassword = '';/connectstr_dbpassword = '$DATABASE_PASSWORD';/" "$WORDPRESS_HOME/wp-config.php"
        sed -i "s/table_prefix  = 'wp_';/table_prefix  = '$TABLE_NAME_PREFIX';/" "$WORDPRESS_HOME/wp-config.php"
}

load_wordpress(){
        if ! grep -q "^Include conf/httpd-wordpress.conf" $HTTPD_CONF_FILE; then
                echo 'Include conf/httpd-wordpress.conf' >> $HTTPD_CONF_FILE
        fi
}

set -e

echo "INFO: DATABASE_HOST:" $DATABASE_HOST
echo "INFO: DATABASE_NAME:" $DATABASE_NAME
echo "INFO: DATABASE_USERNAME:" $DATABASE_USERNAME
echo "INFO: TABLE_NAME_PREFIX:" $TABLE_NAME_PREFIX
echo "INFO: PHPMYADMIN_USERNAME:" $PHPMYADMIN_USERNAME

setup_httpd_log_dir
apachectl start

# That wp-config.php doesn't exist means WordPress is not installed/configured yet.
if [ ! -e "$WORDPRESS_HOME/wp-config.php" ]; then
	echo "INFO: $WORDPRESS_HOME/wp-config.php not found."
	echo "Installing WordPress for the first time ..."
	setup_wordpress
        update_wordpress_config
else
	echo "INFO: $WORDPRESS_HOME/wp-config.php already exists."
fi	

# If local MariaDB is used in wp-config.php
if grep -q "^\$connectstr_dbhost = 'localhost'\|^\$connectstr_dbhost = '127.0.0.1'" "$WORDPRESS_HOME/wp-config.php"; then
	echo "INFO: local MariaDB is used as DB_HOST in wp-config.php."
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
	
	echo "Creating database for WordPress if not exists ..."
	mysql -u root -e "CREATE DATABASE IF NOT EXISTS \`$DATABASE_NAME\` CHARACTER SET utf8 COLLATE utf8_general_ci;"
	echo "Granting user for WordPress ..."
	mysql -u root -e "GRANT ALL ON \`$DATABASE_NAME\`.* TO \`$DATABASE_USERNAME\`@\`$DATABASE_HOST\` IDENTIFIED BY '$DATABASE_PASSWORD'; FLUSH PRIVILEGES;"
	
	echo "Starting local Redis ..."
	redis-server --daemonize yes
	
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
	echo "INFO: local MariaDB is NOT used as DB_HOST in wp-config.php."
fi

apachectl stop
# delay 2 seconds to try to avoid "httpd (pid XX) already running"
sleep 2s

echo "Loading WordPress conf ..."
load_wordpress

echo "Starting Apache httpd -D FOREGROUND ..."
apachectl start -D FOREGROUND
