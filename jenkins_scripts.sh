#!/bin/bash -exv
PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'

load_testdata() {
    local compose_f_opt=$1
    local rc=0
    echo "load testdata"
    nottyopt=''; [[ -t 0 ]] || nottyopt='-T'  # autodetect tty
    #docker-compose $compose_f_opt $projopt run --rm $service bash -l \
    #    -c '>&2echo "test echo stderr, pty"' || true
    #docker-compose $compose_f_opt $projopt run --rm $service bash -l \
    #    -c 'echo "test echo stdout, pty"' || true
    #docker-compose $compose_f_opt $projopt run -T --rm $service bash -l \
    #    -c '>&2echo "test echo stderr, nopty' || true
    #docker-compose $compose_f_opt $projopt run -T --rm $service bash -l \
    #    -c 'echo "test echo stdout, nopty' || true
    docker-compose $compose_f_opt $projopt run $nottyopt --rm $service bash -l \
        -c '/tests/load_data.sh' || rc=$?
    echo "load testdata complete with rc=${rc}"
    return $rc
}


make_postgres_running() {
    local rc=0
    echo 'assure that postgres is up'
    docker-compose $projopt -f dc_postgres.yaml --no-ansi up -d || rc=$?
    if ((rc>0)); then
        echo "'docker-compose -f dc_postgres.yaml up' failed with code=${rc}"
        return $rc
    fi
    sleep 2
    local pg_is_running=$(test_if_running $pg_container)
    if [[ ! "$pg_is_running" ]]; then
        echo "${pg_container} not running"
        return 1
    else
        echo "${pg_container} running"
    fi
}


remove_container_if_not_running() {
    echo 'remove container if no running'
    local status=$(docker container inspect -f '{{.State.Status}}' $container 2>/dev/null || echo '')
    if [[ "$status" ]]; then
        docker container rm -f $container >/dev/null 2>&1 || true # remove any stopped container
    fi
}


remove_containers() {
    echo 'remove containers'
    for cont in $*; do
        local container_found=$(docker container inspect -f '{{.Name}}' $cont 2>/dev/null || true)
        if [[ "$container_found" ]]; then
            docker container rm -f $container_found -v |  perl -pe 'chomp; print " removed\n"'
        fi
    done
}


remove_volumes() {
    echo 'removing volumes'
    for vol in $*; do
        volume_found=$(docker volume ls --format '{{.Name}}' --filter name=^$vol$)  # fail job on command error
        if [[ "$volume_found" ]]; then
            docker volume rm $vol |  perl -pe 'chomp; print " removed\n"'
        fi
    done
}


test_if_running() {
    local cont=$1
    local status=$(docker container inspect -f '{{.State.Status}}' $cont 2>/dev/null || echo '')
    if [[ "$status" == "running" ]]; then
        echo 'running'
    fi
}


verify_python_env() {
    local compose_cfg=$1
    local rc=0
    echo 'verifying python env'
    nottyopt=''; [[ -t 0 ]] || nottyopt='-T'  # autodetect tty
    docker-compose -f $compose_cfg -p 'dc' run $nottyopt --rm $service bash -l \
        -c 'python /tests/test_python_env.py /opt/PVZDweb/requirements.txt' || rc=$?
}


wait_for_container_up() {
    local l_container
    [[ "$1" ]] && l_container=$1 || l_container=$container
    [[ "$2" ]] && wait_max_seconds=$1 || wait_max_seconds=10
    echo "waiting for container status=up"
    local status=''
    until [[ "${status}" == 'running' ]] || (( wait_max_seconds == 0 )); do
        wait_max_seconds=$((wait_max_seconds-=1))
        printf '.'
        sleep 1
        status=$(docker container inspect -f '{{.State.Status}}' $l_container 2>/dev/null || echo '')
    done
    if [[ "${status}" == 'running' ]]; then
        echo "Container $container up"
        return 0
    else
        echo "Container $container not running, status=${status}\n"
        return 1
    fi
}


wait_for_database() {
    local compose_f_opt=$1
    local rc=0
    echo "waiting for database to be ready"
    docker-compose $compose_f_opt -p 'dc' run --rm $service bash -l \
        -c '/opt/PVZDweb/bin/wait_pg_become_ready.sh' || rc=$?
    if ((rc>0)); then
        echo "Database unavailable"
        return $rc
    fi
}