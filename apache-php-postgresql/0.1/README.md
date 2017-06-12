# Docker Image for Apache-PHP-PostgreSQL
## Overview
This Docker image is built for [Azure Web App on Linux](https://docs.microsoft.com/en-us/azure/app-service-web/app-service-linux-intro).

## Components
This docker image contains the following components:

1. PHP          **7.1.2**
2. Apache HTTPD **2.4.25**
3. SSH

Ubuntu 16.04 is used as the base image.

## Features
This docker image enables you to:

- run a Apache/PHP Environment on **Azure Web App on Linux**;
- connect your app site to remote **PostgreSQL** database; 
- ssh to the docker container via the URL like below;
```
        https://<your sitename>.scm.azurewebsites.net/webssh/host
```

### Deploying to Azure
With the button below, you can easily deploy the image to Azure.

[![Deploy to Azure](http://azuredeploy.net/deploybutton.png)](https://azuredeploy.net/)

## How to Upload Your App
1. Use any FTP tool you prefer to connect to the site (you can get the credentials on Azure portal);
2. Upload your app files to the folder /home/site/wwwroot/;

## Startup Log
The startup log file (**entrypoint.log**) is placed under the folder /home/LogFiles.
