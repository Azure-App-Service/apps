#!/bin/bash

set_var_if_null(){
	local varname="$1"
	if [ ! "${!varname:-}" ]; then
		export "$varname"="$2"
	fi
}

echo "WordPress home : $WORDPRESS_HOME"

# if WordPress is not installed/configured
if [ ! -f "$WORDPRESS_HOME/wp-config.php" ]; then
	# set vars for WordPress if not provided
	set_var_if_null "WORDPRESS_DB_HOST" "127.0.0.1"
	set_var_if_null "WORDPRESS_DB_NAME" "wordpress"
	set_var_if_null "WORDPRESS_DB_USERNAME" "wordpress"
	set_var_if_null "WORDPRESS_DB_PASSWORD" "MS173m_QN"
	set_var_if_null "WORDPRESS_DB_TABLE_NAME_PREFIX" "wp_"

	# replace {'localhost',,} with '127.0.0.1'
	if [ "${WORDPRESS_DB_HOST,,}" = "localhost" ]; then
		export WORDPRESS_DB_HOST="127.0.0.1"
		echo "Replace localhost with 127.0.0.1 ... $WORDPRESS_DB_HOST"
	fi

	# check if use native MariaDB
	# if yes, we allow users to use native phpMyAdmin and native Redis server
	if [ $WORDPRESS_DB_HOST = "127.0.0.1" ]; then
		# set vars for phpMyAdmin if not provided
		set_var_if_null 'PHPMYADMIN_USERNAME' 'phpmyadmin'
		set_var_if_null 'PHPMYADMIN_PASSWORD' 'MS173m_QN'

		# start native database 
		service mysql start

		# create database and databse user for WordPress
		mysql -u root -e "create database $WORDPRESS_DB_NAME; grant all on $WORDPRESS_DB_NAME.* to '$WORDPRESS_DB_USERNAME'@'127.0.0.1' identified by '$WORDPRESS_DB_PASSWORD'; flush privileges;"

		# create database user for phpMyAdmin
		mysql -u root -e "create user '$PHPMYADMIN_USERNAME'@'127.0.0.1' identified by '$PHPMYADMIN_PASSWORD'; grant all on *.* to '$PHPMYADMIN_USERNAME'@'127.0.0.1' with grant option; flush privileges;"	
		
		# start native Redis server
		redis-server --daemonize yes
	fi
	
	# update wp-config.php
	cp "$WORDPRESS_HOME/wp-config.php.microsoft" "$WORDPRESS_HOME/wp-config.php"
	sed -i "s/connectstr_dbhost = '';/connectstr_dbhost = '$WORDPRESS_DB_HOST';/" "$WORDPRESS_HOME/wp-config.php"
	sed -i "s/connectstr_dbname = '';/connectstr_dbname = '$WORDPRESS_DB_NAME';/" "$WORDPRESS_HOME/wp-config.php"
	sed -i "s/connectstr_dbusername = '';/connectstr_dbusername = '$WORDPRESS_DB_USERNAME';/" "$WORDPRESS_HOME/wp-config.php"
	sed -i "s/connectstr_dbpassword = '';/connectstr_dbpassword = '$WORDPRESS_DB_PASSWORD';/" "$WORDPRESS_HOME/wp-config.php"
	sed -i "s/table_prefix  = 'wp_';/table_prefix  = '$WORDPRESS_DB_TABLE_NAME_PREFIX';/" "$WORDPRESS_HOME/wp-config.php"
	chown www-data:www-data "$WORDPRESS_HOME/wp-config.php"
fi

# start Apache HTTPD
httpd -DFOREGROUND
