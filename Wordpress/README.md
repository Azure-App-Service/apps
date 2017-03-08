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
- connect your WordPress site to **Azure ClearDB** or the builtin MariaDB;
- leverage **Azure Redis Cache** or the builtin Redis cache server;

## Limitations
- Some unexpected issues may happen after you scale out your site to multiple instances, if you deploy a WordPress site on Azure with this docker image and use the MariaDB built in this docker image as the database.
- The Redis cache built in this docker image is available only when you use the MariaDB built in this docker image as the database.
- The phpMyAdmin built in this docker image is available only when you use the MariaDB built in this docker image as the database.

## Deploying / Running
You can specify the following environment variables when deploying the image to Azure or running it on your Docker engine's host.

Name | Default Value
---- | -------------
WORDPRESS_DB_HOST | 127.0.0.1
WORDPRESS_DB_NAME | wordpress
WORDPRESS_DB_USERNAME | wordpress
WORDPRESS_DB_PASSWORD | MS173m_QN
WORDPRESS_DB_TABLE_NAME_PREFIX | wp_
PHPMYADMIN_USERNAME | phpmyadmin
PHPMYADMIN_PASSWORD | MS173m_QN

### Deploying to Azure
With the button below, you can easily deploy the image to Azure.

[![Deploy to Azure](http://azuredeploy.net/deploybutton.png)](https://azuredeploy.net/)

At the SETUP page, as shown below, you can change default values of these environment variables with yours.

![WordPress Deploy to Azure SETUP page](https://raw.githubusercontent.com/fanjeffrey/Images/master/Microsoft/docker-library/wordpress_deploy_setup.PNG)

### Running on Docker engine's host
The **docker run** command below will get you a container that has a WordPress site connected to the builtin MariaDB, and has the builtin Redis cache server started, and has the builtin phpMyAdmin site enabled.
```
docker run -d -t -p 80:80 fanjeffrey/wordpress:4.7.2
```

The command below will connect the WordPress site within your Docker container to an Azure ClearDb.
```
docker run -d -t -p 80:80 \
    -e "WORDPRESS_DB_HOST=<your_cleardb_host_name>" \
    -e "WORDPRESS_DB_NAME=<your_db_name>" \
    -e "WORDPRESS_DB_USERNAME=<your_db_username>" \
    -e "WORDPRESS_DB_PASSWORD=<your_db_password>" \
    -e "WORDPRESS_DB_TABLE_NAME_PREFIX=<your_table_name_prefix>" \
    fanjeffrey/wordpress:4.7.2
```

When you use 127.0.0.1 as the database host, you can customize phpMyAdmin username and password.
```
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

## The Builtin MariaDB server
The builtin MariaDB server uses port 3306.

## The Builtin phpMyAdmin Site
If you're using the builtin MariaDB, you can access the builtin phpMyAdmin site with a URL like below:

**http://<hostname>[port]/phpmyadmin**

## The Builtin Redis Cache Server
If you're using the builtin MariaDB, you can leverage the builtin Redis cache server with WordPress cache plugins. For example, the [Redis Object Cache](https://wordpress.org/plugins/redis-cache/).

The builtin Redis cache server uses port 6379.
