#!/usr/bin/env bash

# The details of the gunicorn configuration are

scriptsdir=$(cd "$(dirname ${BASH_SOURCE[0]})" && pwd)
source $scriptsdir/setenv.sh

#su - $CONTAINERUSER -c "source /opt/venv/pvzdweb/bin/activate; export CONTAINERUSER=$CONTAINERUSER; /opt/PVZDweb/bin/start_webapp.sh &"

source /opt/venv/pvzdweb/bin/activate

gunicorn pvzdweb.wsgi:application -c /config/etc/gunicorn/config.py