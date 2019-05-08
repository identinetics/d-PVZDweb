#!/bin/bash

while getopts ':fv' opt; do
  case $opt in
    f) force_opt='-f';;
    v) verbose_opt='-v';;
    *) echo "usage: $0 OPTIONS
       Configure apache + shibd and generate SP metadata

       OPTIONS:
       -f  force
       -v  verbose
       "; exit 0;;
  esac
done
shift $((OPTIND-1))


mkdir -p /var/log/logrotate
mkdir -p /var/log/nginx/history
mkdir -p /var/log/sigproxy/history
mkdir -p /var/log/webapp/history

logrotate $verbose_opt --state /var/log/logrotate/logrotate.status /opt/etc/logrotate/logrotate.conf
