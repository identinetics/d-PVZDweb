#!/bin/bash

scriptdir=$(cd "$(dirname ${BASH_SOURCE[0]})" && pwd)

main() {
    start_appserver
    start_sig_proxy
    start_reverse_proxy
    keep_running
    trap propagate_signals SIGTERM
}


start_appserver() {
    # start gunicorn
    # settings.py/INSTALLED_APPS controls which webapps are serviced in this instance
    source /etc/profile.d/pvzdweb.sh
    export PYTHONPATH=$APPHOME:$APPHOME/PVZDlib
    # missing error message "worker failed ot boot"? add --preload option
    mkdir -p /var/run/webapp/
    gunicorn --config=/opt/etc/gunicorn/webapp_config.py pvzdweb.wsgi:application --pid /var/run/webapp/gunicorn.pid &
}


start_sig_proxy() {
    source /opt/venv/sigproxy/bin/activate
    PYTHONPATH=/opt/seclay_xmlsig_proxy
    mkdir -p /var/run/sigproxy
    gunicorn --config=/opt/etc/gunicorn/sigproxy_config.py wsgi:application --pid /var/run/sigproxy/gunicorn.pid &
}


start_reverse_proxy() {
    # start nginx (used to serve static files)
    /usr/sbin/nginx -c /opt/etc/nginx/nginx.conf
}


keep_running() {
    echo 'wait for SIGINT/SIGKILL'
    while true; do sleep 36000; done
    echo 'interrupted; exiting shell -> may exit the container'
}


propagate_signals() {
    kill -s SIGTERM $(cat /var/run/webapp/gunicorn.pid)
    kill -s SIGQUIT $(cat /var/run/nginx/nginx.pid)
}


main $@
