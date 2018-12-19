#!/usr/bin/env bash


# start nginx (used to serve static files)

/usr/sbin/nginx -c /config/etc/nginx/nginx.conf


# start gunicorn
# settings.py/INSTALLED_APPS controls which webapps are serviced in this instance

source $PROJ_HOME/bin/setenv.sh
source /opt/venv/pvzdweb/bin/activate
gunicorn pvzdweb.wsgi:application -c /config/etc/gunicorn/config.py &
