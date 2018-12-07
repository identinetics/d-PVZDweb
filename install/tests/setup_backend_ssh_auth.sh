#!/usr/bin/env bash


cd /home/backend/.ssh/
cp -pn /testdata-setup/root/dot_ssh/authorized_keys .
chown backend authorized_keys
chmod 640 authorized_keys
namei -l authorized_keys