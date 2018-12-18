#!/usr/bin/env bash


# start nginx (used to serve static files)

/usr/sbin/nginx -c /config/etc/nginx/nginx.conf


# start gunicorn
# settings.py/INSTALLED_APPS controls which webapps are serviced in this instance

/scripts/wait_pg_become_ready.sh
source /opt/PVZDweb/bin/setenv.sh
source /opt/venv/pvzdweb/bin/activate
gunicorn pvzdweb.wsgi:application -c /config/etc/gunicorn/config.py &
