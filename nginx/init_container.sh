#!/bin/bash
[ -e "/home/site/nginx.conf" ] && cp "/home/site/nginx.conf" "/etc/nginx/nginx.conf"
/usr/bin/supervisord