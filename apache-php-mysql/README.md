# Docker Image for Apache-PHP-MySQL
## Overview
This Docker image is built for [Azure Web App on Linux](https://docs.microsoft.com/en-us/azure/app-service-web/app-service-linux-intro).

## Components
This docker image contains the following components:

1. PHP          **7.1.2**
2. Apache HTTPD **2.4.25**
3. MariaDB      **10.0+**
4. phpMyAdmin   **4.6.6**
5. SSH

Ubuntu 16.04 is used as the base image.

## Features
This docker image enables you to:

- run a Apache/PHP/MySQL Environment on **Azure Web App on Linux**;
- connect your App site to **Azure ClearDB** or the builtin MariaDB;
- manage the build-in MariaDB with the built-in phpMyAdmin;
- ssh to the docker container via the URL like below;
```
        https://<your sitename>.scm.azurewebsites.net/webssh/host
```

## Deploying / Running
You can specify the following environment variables when deploying the image to Azure or running it on your Docker engine's host.

Name | Default Value
---- | -------------
DATABASE_NAME | appdb
DATABASE_USERNAME | appuser
DATABASE_PASSWORD | MS173m_QN
PHPMYADMIN_USERNAME | phpmyadmin
PHPMYADMIN_PASSWORD | MS173m_QN

### Deploying to Azure
With the button below, you can easily deploy the image to Azure.

[![Deploy to Azure](http://azuredeploy.net/deploybutton.png)](https://azuredeploy.net/)

## The Builtin MariaDB server
The builtin MariaDB server uses port 3306.

## The Builtin phpMyAdmin Site
You can access the builtin phpMyAdmin site with a URL like below if you're using the build-in MariaDB:

**http://hostname[:port]/phpmyadmin**

## How to install APP
1. Use any FTP tool you prefer to connect to the site (you can get the credentials on Azure portal);
2. Upload the files of the app that you want to install to the folder /home/site/wwwroot/;
3. Create database on the built-in MariaDB database for your app with the build-in phpMyAdmin;
4. Update the config file of your app with your created database information;

## Startup Log
The startup log file (**entrypoint.log**) is placed under the folder /home/LogFiles.
