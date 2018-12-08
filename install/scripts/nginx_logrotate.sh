#!/usr/bin/env bash

# keep 1 level of logfile history

cd /var/log/nginx
mv -f error.log error.log.previous
mv -f access.log access.log.previous
kill -USR1 $(cat nginx.pid)
