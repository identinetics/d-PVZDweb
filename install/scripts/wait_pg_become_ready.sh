#!/usr/bin/env bash

# delay until postgres is ready, up to PGSTARTUP_RETRIES seconds

until psql -h $POSTGRES_HOST -U $POSTGRES_USER -d $DATABASE -c "select 1" > /dev/null 2>&1 || (( PGSTARTUP_RETRIES == 0 )); do
    echo "Waiting for postgres server to start, $((PGSTARTUP_RETRIES)) remaining attempts..." 
    PGSTARTUP_RETRIES=$((PGSTARTUP_RETRIES-=1)) 
    sleep 1 
done
