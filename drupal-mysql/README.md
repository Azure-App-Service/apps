# Docker Image for Drupal with MySQL
## Overview
This Drupal (with MySQL) Docker image is built for [Azure Web App on Linux](https://docs.microsoft.com/en-us/azure/app-service-web/app-service-linux-intro).

## Components
This docker image contains the following components:

1. Drupal       **8.3.0-rc2**
2. PHP          **7.1.2**
3. Apache HTTPD **2.4.25**
4. MariaDB      **10.0+**
5. phpMyAdmin   **4.6.6**

Ubuntu 16.04 is used as the base image.

## Features
This docker image enables you to:

- run a Drupal site on **Azure Web App on Linux**;
- connect your Drupal site to **Azure ClearDB** or the builtin MariaDB;

## Limitations
- Some unexpected issues may happen after you scale out your site to multiple instances, if you deploy a Drupal site on Azure with this docker image and use the MariaDB built in this docker image as the database.
- The phpMyAdmin built in this docker image is available only when you use the MariaDB built in this docker image as the database.

## Deploying / Running
You can specify the following environment variables when deploying the image to Azure or running it on your Docker engine's host.

Name | Default Value
---- | -------------
DRUPAL_DB_HOST | localhost
DRUPAL_DB_NAME | drupal
DRUPAL_DB_USERNAME | drupal
DRUPAL_DB_PASSWORD | MS173m_QN
PHPMYADMIN_USERNAME | phpmyadmin
PHPMYADMIN_PASSWORD | MS173m_QN

### Deploying to Azure
With the button below, you can easily deploy the image to Azure.

[![Deploy to Azure](http://azuredeploy.net/deploybutton.png)](https://azuredeploy.net/)

At the SETUP page, as shown below, you can change default values of these environment variables with yours.

![Drupal Deploy to Azure SETUP page](https://raw.githubusercontent.com/fanjeffrey/Images/master/Microsoft/docker-library/drupal_deploy_setup.PNG)

## The Builtin MariaDB server
The builtin MariaDB server uses port 3306.

## The Builtin phpMyAdmin Site
If you're using the builtin MariaDB, you can access the builtin phpMyAdmin site with a URL like below:

**http://hostname[:port]/phpmyadmin**

## How to change database connection to a remote server
1. Use any FTP tool you prefer to connect to the site (you can get the credentials on Azure portal);
2. Download /home/site/wwwroot/sites/default/settings.php to your local folder;
3. Open settings.php, find the following lines, and then update them;
    ```
    #do not remove/uncomment the following line.
    #docker: DRUPAL_DB_HOST=localhost
    $databases['default']['default'] = array (
        'database' => 'drupal',
        'username' => 'drupal',
        'password' => 'MS173m_QN',
        'prefix' => 'dp_',
        'host' => 'localhost',
        'port' => '3306',
        'namespace' => 'Drupal\\Core\\Database\\Driver\\mysql',
        'driver' => 'mysql',
    );
    ```
    NOTE: you need also change the line "#docker: DRUPAL_DB_HOST=localhost" to "#docker: DRUPAL_DB_HOST=<your-db-server-name/IP address>". This line is required by entrypoint.sh.

4. Upload settings.php back to overwrite;

## How to install modules
1. Use any FTP tool you prefer to connect to the site (you can get the credentials on Azure portal);
2. Upload the tar file of the module that you want to install to the folder /home/site/wwwroot/modules;
3. Extract the contents into a sub-folder under /home/site/wwwroot/modules;

For more information, please see the README.txt under /home/site/wwwroot/modules.