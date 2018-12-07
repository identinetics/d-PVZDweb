#!/usr/bin/env bash

# start webapp and sshd

echo 'starting webapp in background' 1>&2
su - $CONTAINERUSER -c "export CONTAINERUSER=$CONTAINERUSER; /opt/PVZDweb/bin/start_webapp.sh"

echo 'starting ssh' 1>&2
/scripts/start_sshd.sh

#echo 'keeping git repos in sync'
#su - $CONTAINERUSER -c "/scripts/repo_sync.sh"