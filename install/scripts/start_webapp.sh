#!/usr/bin/env bash

# The details of the gunicorn configuration are

source /opt/PVZDweb/bin/setenv.sh

#su - $CONTAINERUSER -c "source /opt/venv/pvzdweb/bin/activate; export CONTAINERUSER=$CONTAINERUSER; /opt/PVZDweb/bin/start_webapp.sh &"

source /opt/venv/pvzdweb/bin/activate

gunicorn pvzdweb.wsgi:application -c /config/etc/gunicorn/config.py
