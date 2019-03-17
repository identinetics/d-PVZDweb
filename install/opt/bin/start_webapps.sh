#!/bin/bash


main() {
    start_appserver
    start_sig_proxy
    start_reverse_proxy
    keep_running
}




start_appserver() {
    # start gunicorn
    # settings.py/INSTALLED_APPS controls which webapps are serviced in this instance
    source /etc/profile.d/pvzdweb.sh
    gunicorn pvzdweb.wsgi:application -c /opt/etc/gunicorn_webapp/config.py &
}


start_sig_proxy() {
    source /opt/venv/sigproxy/bin/activate
    gunicorn wsgi:application -c /opt/etc/gunicorn_sigproxy/config.py &
}


start_reverse_proxy() {
    # start nginx (used to serve static files)
    /usr/sbin/nginx -c /opt/etc/nginx/nginx.conf
}


keep_running() {
    echo 'stay forever'
    while true; do sleep 36000; done
    echo 'interrupted; exiting shell -> may exit the container'
}


main $@