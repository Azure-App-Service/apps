#!/bin/bash

set_var_if_null(){
	local varname="$1"
	if [ ! "${!varname:-}" ]; then
		export "$varname"="$2"
	fi
}

test ! -d $WORDPRESS_HOME_AZURE && echo "INFO: WordPress site home on Azure: $WORDPRESS_HOME_AZURE not found!"

# That wp-config.php doesn't exist means WordPress is not installed/configured yet.
if [ ! -f "$WORDPRESS_HOME/wp-config.php" ]; then
	# create wp-config.php
	mv $WORDPRESS_SOURCE/wp-config.php.microsoft $WORDPRESS_SOURCE/wp-config.php
	# set WordPress vars if they're not declared or unset
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
       	# update wp-config.php with the vars above 
        sed -i "s/connectstr_dbhost = '';/connectstr_dbhost = '$WORDPRESS_DB_HOST';/" "$WORDPRESS_SOURCE/wp-config.php"
        sed -i "s/connectstr_dbname = '';/connectstr_dbname = '$WORDPRESS_DB_NAME';/" "$WORDPRESS_SOURCE/wp-config.php"
        sed -i "s/connectstr_dbusername = '';/connectstr_dbusername = '$WORDPRESS_DB_USERNAME';/" "$WORDPRESS_SOURCE/wp-config.php"
        sed -i "s/connectstr_dbpassword = '';/connectstr_dbpassword = '$WORDPRESS_DB_PASSWORD';/" "$WORDPRESS_SOURCE/wp-config.php"
        sed -i "s/table_prefix  = 'wp_';/table_prefix  = '$WORDPRESS_DB_TABLE_NAME_PREFIX';/" "$WORDPRESS_SOURCE/wp-config.php"

	# Because Azure Web App on Linux uses /home/site/wwwroot,
	# so if /home/site/wwwroot doesn't exist, 
	# we think the container is not running on Auzre.
	if [ ! -d "$WORDPRESS_HOME_AZURE" ]; then
        	rm -rf $WORDPRESS_HOME && mkdir -p $WORDPRESS_HOME
		rm -rf $PHPMYADMIN_HOME && mkdir -p $PHPMYADMIN_HOME
		rm -rf $MARIADB_DATA_DIR && mkdir -p $MARIADB_DATA_DIR
		rm -rf $HTTPD_LOG_DIR && mkdir -p $HTTPD_LOG_DIR
		rm -rf $MARIADB_LOG_DIR && mkdir -p $MARIADB_LOG_DIR
	else
		test ! -d $PHPMYADMIN_HOME_AZURE && mkdir -p $PHPMYADMIN_HOME_AZURE
		test ! -d $MARIADB_DATA_DIR_AZURE && mkdir -p $MARIADB_DATA_DIR_AZURE
		test ! -d $HTTPD_LOG_DIR_AZURE && mkdir -p $HTTPD_LOG_DIR_AZURE
		test ! -d $MARIADB_LOG_DIR_AZURE && mkdir -p $MARIADB_LOG_DIR_AZURE
	fi
        cp -R $WORDPRESS_SOURCE/* $WORDPRESS_HOME/ && chown -R www-data:www-data $WORDPRESS_HOME/ && rm -rf $WORDPRESS_SOURCE
        cp -R $PHPMYADMIN_SOURCE/* $PHPMYADMIN_HOME/ && chown -R www-data:www-data $PHPMYADMIN_HOME/ && rm -rf $PHPMYADMIN_SOURCE
        cp -R $MARIADB_DATA_DIR_TEMP/* $MARIADB_DATA_DIR/ && chown -R mysql:mysql $MARIADB_DATA_DIR/ && rm -rf $MARIADB_DATA_DIR_TEMP
	chown -R www-data:www-data $HTTPD_LOG_DIR/
	chown -R mysql:mysql $MARIADB_LOG_DIR/

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
else
	if grep "connectstr_dbhost = '127.0.0.1'" "$WORDPRESS_HOME/wp-config.php"; then
		service mysql start
		redis-server --daemonize yes
	fi
fi

# start Apache HTTPD
httpd -DFOREGROUND
