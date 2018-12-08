#!/usr/bin/env bash

# start webapp and sshd

echo 'starting http proxy in background' 1>&2
/scripts/start_httpproxy.sh

echo 'starting webapp in background' 1>&2
/scripts/start_webapp.sh

echo 'starting ssh' 1>&2
/scripts/start_sshd.sh

#echo 'keeping git repos in sync'
#su - $CONTAINERUSER -c "/scripts/repo_sync.sh"