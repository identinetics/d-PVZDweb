#!/usr/bin/env bash

# delay until postgres is ready, up to PGSTARTUP_RETRIES seconds
[[ "$PGSTARTUP_RETRIES" ]] || PGSTARTUP_RETRIES=30

scriptsdir=$(cd $(dirname $BASH_SOURCE[0]) && pwd)
source $scriptsdir/postgres_settings.sh
until psql -c "select 1" > /dev/null 2>&1 || (( PGSTARTUP_RETRIES == 0 )); do
    echo "Waiting for postgres server to start, $((PGSTARTUP_RETRIES)) remaining attempts..." 
    PGSTARTUP_RETRIES=$((PGSTARTUP_RETRIES-=1)) 
    sleep 1 
done
