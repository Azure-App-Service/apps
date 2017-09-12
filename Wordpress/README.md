# WordPress Docker Image

>## Note : This image is no longer maintained by the team . This is archived image. We recommend users to use this [apache-php-mysql](https://github.com/azure-app-service/apps) and then bring in their own code for WordPress 

## Overview
A WordPress Docker image which is built with the Dockerfile under this repo can run on both [Azure Web App on Linux]>(https://docs.microsoft.com/en-us/azure/app-service-web/app-service-linux-intro) and your Docker engines's host.


## Components
This docker image currently contains the following components:

1. WordPress    **4.8**
2. PHP          **7.1.2**
3. Apache HTTPD **2.4.25**
4. MariaDB      **10.0+**
5. Redis        **3.2.8**
6. phpMyAdmin   **4.6.6**
7. SSH

## Features
This docker image enables you to:

- run a WordPress site on **Azure Web App on Linux** or your Docker engine's host;
- connect your WordPress site to **Azure ClearDB** or the builtin MariaDB;
- leverage **Azure Redis Cache** or the builtin Redis cache server;
- ssh to the docker container via the URL like below;
```
        https://<your sitename>.scm.azurewebsites.net/webssh/host
```

## Limitations
- Some unexpected issues may happen after you scale out your site to multiple instances, if you deploy a WordPress site on Azure with this docker image and use the MariaDB built in this docker image as the database.
- The Redis cache built in this docker image is available only when you use the MariaDB built in this docker image as the database.
- The phpMyAdmin built in this docker image is available only when you use the MariaDB built in this docker image as the database.

## Deploying / Running
You can specify the following environment variables when deploying the image to Azure or running it on your Docker engine's host.

Name | Default Value
---- | -------------
DATABASE_HOST | localhost
DATABASE_NAME | wordpress
DATABASE_USERNAME | wordpress
DATABASE_PASSWORD | MS173m_QN
TABLE_NAME_PREFIX | wp_
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
docker run -d -t -p 80:80 appsvc/apps:wordpress-0.2
```

The command below will connect the WordPress site within your Docker container to an Azure ClearDb.
```
docker run -d -t -p 80:80 \
    -e "DATABASE_HOST=<your_cleardb_host_name>" \
    -e "DATABASE_NAME=<your_db_name>" \
    -e "DATABASE_USERNAME=<your_db_username>" \
    -e "DATABASE_PASSWORD=<your_db_password>" \
    -e "TABLE_NAME_PREFIX=<your_table_name_prefix>" \
    appsvc/apps:wordpress-0.2
```

When you use "localhost" as the database host, you can customize phpMyAdmin username and password.
```
docker run -d -t -p 80:80 \
    -e "DATABASE_HOST=localhost" \
    -e "DATABASE_NAME=<your_db_name>" \
    -e "DATABASE_USERNAME=<your_db_username>" \
    -e "DATABASE_PASSWORD=<your_db_password>" \
    -e "TABLE_NAME_PREFIX=<your_table_name_prefix>" \
    -e "PHPMYADMIN_USERNAME=<your_phpmyadmin_username>" \
    -e "PHPMYADMIN_PASSWORD=<your_phpmyadmin_password>" \
    appsvc/apps:wordpress-0.2
```

## The Builtin MariaDB server
The builtin MariaDB server uses port 3306.

## The Builtin phpMyAdmin Site
If you're using the builtin MariaDB, you can access the builtin phpMyAdmin site with a URL like below:

**http://hostname[:port]/phpmyadmin**

## The Builtin Redis Cache Server
If you're using the builtin MariaDB, you can leverage the builtin Redis cache server with WordPress cache plugins. For example, the [Redis Object Cache](https://wordpress.org/plugins/redis-cache/).

The builtin Redis cache server uses port 6379.

## Startup Log
The startup log file (**entrypoint.log**) is placed under the folder /home/LogFiles.

## Change Log
- **Version 0.2**
  1. Supports SSH. See [Dockerfile](0.2/Dockerfile), [sshd_config](0.2/sshd_config) here;
  2. Uses LinuxFxVersion instead to set Docker container. See [azuredeploy.json](azuredeploy.json) here;
- **Version 0.3**
  1. Supports uploading large files. See [php.ini](0.3/php.ini) here;
  2. Supports Zlib. See [Dockerfile](0.3/Dockerfile) here.
