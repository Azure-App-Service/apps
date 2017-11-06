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
- connect your App site to **Azure ClearDB** or the built-in MariaDB;
- manage the build-in MariaDB with the built-in phpMyAdmin(You need set DATABASE_TYPE to **"local"**);
- ssh to the docker container via the URL like below;
```
        https://<your sitename>.scm.azurewebsites.net/webssh/host
```

## Deploying / Running
Here are default environment variables when deploying the image to Azure.
- DATABASE_TYPE | remote

### Deploying on azure
1. Go to Azure portal, go to the blade of your web app.
2. Click *"Application settings"* and type the following in the field *"App settings"*
    - [share the /home/ directory](https://docs.microsoft.com/en-us/azure/app-service/containers/app-service-linux-faq#custom-containers)
        * WEBSITES_ENABLE_APP_SERVICE_STORAGE | true
    - enable the build-in MariaDB
        * DATABASE_TYPE | local

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
Startup log from entrypoint.sh is disabled by default. To enable startup log, you can follow the steps below.
1. Go to Azure portal, go to the blade of your web app.
2. Click *"Diagnostics logs"*.
3. On the *"Diagnostics logs"* blade, selecet *"File System"* under *"Docker Container logging"*.
4. Set *"Quota"* and *"Retention Period"*, and Click *"Save"*.
5. Go to the "Overview" blade, Restart your web app by clicking *"Stop"* and then *"start"*.

On Webssh run the command below to check if the startup logs from entrypoint.sh is enabled.
```
	#Replace example with your actual log file name.
	cat /home/LogFiles/2017_10_10_RDXXXXXX_docker.log
```

## Change Log
- **Version 0.4**
  1. Update the section Startup Log in README.md.
  2. Create default database - azurelocaldb.(You need set DATABASE_TYPE to **"local"**)
  3. Considering security, please set database authentication info on [*"App settings"*](#deploying-on-azure) when enable **"local"** mode.   
     Note: the credentials below is also used by phpMyAdmin.
      -  DATABASE_USERNAME | <*your phpMyAdmin user*>
      -  DATABASE_PASSWORD | <*your phpMyAdmin password*>

- **Version 0.3** 
  1. Enable mod_deflate.
  2. Drop using azuredeploy.json.

- **Version 0.2** 
  1. Supports uploading large files. See [php.ini](0.2/php.ini) here.
  2. New app setting item: DATABASE_TYPE, default value is "remote". You can set it to "local" to start the built-in MySQL database server. See [entrypoint.sh](0.2/entrypoint.sh) for more information.
  3. Dropped 3 app setting items: DATABASE_NAME, DATABASE_USER, and DATABASE_PASSWORD. Removal of these items has no impacts on your existing database or site contents.
