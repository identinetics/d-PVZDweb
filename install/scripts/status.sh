#!/bin/bash

# show main processes
echo "show container processes (expect nginx, lighthttpd, python3/webapp.py and sshd)"
ps -eaf | head -1
ps -eaf | grep -E 'nginx: master | lighttpd |sshd_config|webapp.py' |grep -v '00 grep'
