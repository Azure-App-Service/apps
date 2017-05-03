# Docker Image for Django
## Overview
This Django Docker image is built for [Azure Web App on Linux](https://docs.microsoft.com/en-us/azure/app-service-web/app-service-linux-intro).

## Components
This Docker image contains the following components:

1. Django **1.11**
2. Python **3.5.2**
3. nginx **1.10.0**
4. uWSGI **2.0.15**
5. Psycopg2 **2.7.1**

Ubuntu 16.04 is used as the base image.

The stack of components:
```
Browser <-> nginx <-> /tmp/uwsgi.sock <-> uWSGI <-> Python/Django <-> Psycopg2 <-> remote PostgreSQL database
```

## Features
This docker image enables you to:
- run a site based on Django on **Azure Web App on Linux**;
- connect you site to a remote PostgreSQL database;

## Deploying to Azure
With the button below, you can easily deploy this image to Azure.

[![Deploy to Azure](http://azuredeploy.net/deploybutton.png)](https://azuredeploy.net/)

## Predefined Nginx Locations
This docker image defines the following nginx locations for your static files.
- /images
- /css
- /js
- /static

For more information, see [nginx default site conf](./nginx-default-site).

## uWSGI INI
This docker image contains a default uWSGI ini file which is placed under /home/uwsgi and invoked like below:
```
uwsgi --uid www-data --gid www-data --ini=$UWSGI_INI_DIR/uwsgi.ini
```

You can customeize this ini file, and upload to /home/uwsgi to overwrite.

## Startup Log
The startup log file (**entrypoint.log**) is placed under the folder /home/LogFiles.

## How to Deploy Your Django Project
1. Use any FTP tool you prefer to connect to the site (you can get the credentials on Azure portal).
2. Upload your Django project to /home/site/wwwroot.
3. Customize /home/uwsgi/uwsgi.ini file according to your project's requirements. For example, if your project name is "abc", then you need change the "module" like below.
	```
	# Django's wsgi file
	module=abc.wsgi
	```
4. Save and upload uwsgi.ini back to /home/uwsgi to overwrite.

