# WordPress Docker Image
## Overview
A WordPress Docker image which is built with the Dockerfile under this repo can run on both [Azure Web App on Linux](https://docs.microsoft.com/en-us/azure/app-service-web/app-service-linux-intro) and your Docker engines's host.

## Components
This docker image currently contains the following components:

1. WordPress    **4.7.2**
2. PHP          **7.1.1**
3. Apache HTTPD **2.4.25**
4. MariaDB      **10.0+**
5. Redis        **3.2.8**
6. phpMyAdmin   **4.6.6**

## Features
This docker image enables you to:

- run a WordPress site on **Azure Web App on Linux** or your Docker engine's host;
- connect your WordPress site to **Azure ClearDB** or the MariaDB built in this docker image;
- leverage **Azure Redis Cache** or the Redis cache server built in this docker image;

## Limitations
- Some unexpected issues may happen after you scale out your site to multiple instances, if you deploy a WordPress site on Azure with this docker image and use the MariaDB built in this docker image as the database.
- The Redis cache built in this docker image is available only when you use the MariaDB built in this docker image as the database.
- The phpMyAdmin built in this docker image is available only when you use the MariaDB built in this docker image as the database.

## Fast deploying a WordPress site to Azure
[![Deploy to Azure](http://azuredeploy.net/deploybutton.png)](https://azuredeploy.net/)

## Running this image on your Docker engine's host
```
docker run -d -t -p 80:80 fanjeffrey/wordpress:4.7.2
```

## Configurations
Below list the environment variables which are used in this docker image.

Name | Default Value
---- | -------------
WORDPRESS_DB_HOST | 127.0.0.1
WORDPRESS_DB_NAME | wordpress
WORDPRESS_DB_USERNAME | wordpress
WORDPRESS_DB_PASSWORD | MS173m_QN
WORDPRESS_DB_TABLE_NAME_PREFIX | wp_
PHPMYADMIN_USERNAME | phpmyadmin
PHPMYADMIN_PASSWORD | MS173m_QN

You can change these default values at the **SETUP** page when deploying with the **Deploy to Azure** button above.

![WordPress Deploy to Azure SETUP page](https://raw.githubusercontent.com/fanjeffrey/Images/master/Microsoft/docker-library/wordpress_deploy_setup.PNG)

Or when you use the **docker run** command with this image on your Docker engine's host. See the examples below.
```
# use Azure ClearDB as the database host
docker run -d -t -p 80:80 \
    -e "WORDPRESS_DB_HOST=<your_cleardb_host_name>" \
    -e "WORDPRESS_DB_NAME=<your_db_name>" \
    -e "WORDPRESS_DB_USERNAME=<your_db_username>" \
    -e "WORDPRESS_DB_PASSWORD=<your_db_password>" \
    -e "WORDPRESS_DB_TABLE_NAME_PREFIX=<your_table_name_prefix>" \
    fanjeffrey/wordpress:4.7.2
```
```
# when you use 127.0.0.1 as the database host, you can customize phpMyAdmin username and password.
docker run -d -t -p 80:80 \
    -e "WORDPRESS_DB_HOST=127.0.0.1" \
    -e "WORDPRESS_DB_NAME=<your_db_name>" \
    -e "WORDPRESS_DB_USERNAME=<your_db_username>" \
    -e "WORDPRESS_DB_PASSWORD=<your_db_password>" \
    -e "WORDPRESS_DB_TABLE_NAME_PREFIX=<your_table_name_prefix>" \
    -e "PHPMYADMIN_USERNAME=<your_phpmyadmin_username>" \
    -e "PHPMYADMIN_PASSWORD=<your_phpmyadmin_password>" \
    fanjeffrey/wordpress:4.7.2
```