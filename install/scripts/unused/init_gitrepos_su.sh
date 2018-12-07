#!/usr/bin/env bash

# call init_gitrepos as non-root

if (( $(id -u) == 0 )); then
    su - $CONTAINERUSER -c "export CONTAINERUSER=$CONTAINERUSER; /scripts/init_gitrepos.sh" 1>&2
else
    /scripts/init_gitrepos.sh 1>&2
fi
