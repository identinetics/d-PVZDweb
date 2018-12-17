#!/usr/bin/env bash

# start webapp and sshd

echo 'starting http proxy in background' 1>&2
/scripts/start_httpproxy.sh

echo 'starting webapp in background' 1>&2
/scripts/wait_pg_become_ready.sh
/scripts/start_webapp.sh

# disabled ssh/git for current configuration
#echo 'starting sshd' 1>&2
#/scripts/start_sshd.sh

#echo 'keeping git repos in sync'
#su - $CONTAINERUSER -c "/scripts/repo_sync.sh"