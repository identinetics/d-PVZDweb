#!/bin/bash


# start nginx (used to serve static files)

/usr/sbin/nginx -c /config/etc/nginx/nginx.conf


# start gunicorn
# settings.py/INSTALLED_APPS controls which webapps are serviced in this instance

source /etc/profile.d/pvzdweb.sh
gunicorn pvzdweb.wsgi:application -c /config/etc/gunicorn/config.py &

echo 'stay forever'
while true; do sleep 36000; done

echo 'interrupted; exiting shell -> may exit the container'
