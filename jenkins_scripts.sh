#!/usr/bin/env bash

set_docker_artifact_names() {
    COMPOSE_PROJECT_NAME='dc' # prefix for containers when using docker-compse RUN and volumes without explicit name clause
    container='mdreg'
    network='dfrontend'
    service='mdreg'

}

create_docker_network() {
    network_found=$(docker network ls  --format '{{.Name}}' --filter name=$network)
    if [[ ! "$network_found" ]]; then
        docker network create --driver bridge --subnet=10.1.2.0/24 \
            -o com.docker.network.bridge.name=br-$network $network
    fi
}


load_testdata() {
    echo "load initial testdata"
    ttyopt=''; [[ -t 0 ]] && ttyopt='-T'  # autodetect tty
    if (( $is_running == 0 )); then
        docker-compose -f dc.yaml exec $ttyopt $service $PROJ_HOME/tests/load_data.sh
    else
        docker-compose -f dc.yaml run $ttyopt --rm $service $PROJ_HOME/tests/load_data.sh
    fi
}


load_yaml_config() {
    set -e
    check_python3
    # config.py will create 'export X=Y' statements on stdout; source it by executing the subshell
    tmpfile="/tmp/dcshell-build${$}"
    $($DCSHELL_HOME/config.py $projdir_opt \
        -k container_name -k image -k container_name -k build.dockerfile $dc_opt_prefixed) \
        > $tmpfile
    source $tmpfile
    set +e
    rm -f $$tmpfile
}


remove_containers() {
    for cont in 'mdreg' 'dc_mdreg_run_1' 'postgres'; do
        container_found=$(docker container ls --format '{{.Names}}' | egrep ^$cont$)
        if [[ "$container_found" ]]; then
            docker container rm -f $cont -v
        fi
    done
}


remove_volumes() {
    for vol in 'postgres.data' \
               'pvzdweb.config' \
               'pvzdweb.var_lib_git' \
               'pvzdweb.var_log' \
               'pvzdweb.opt_PVZDweb_database'
    do
        volume_found=$(docker volume ls --format '{{.Name}}' | egrep ^$vol$)
        if [[ "$volume_found" ]]; then
            docker volume rm $vol
        fi
    done
}


test_if_running() {
    if [[ "$(docker container ls -f name=$container | egrep -v ^CONTAINER)" ]]; then
        is_running=0  # running
    else
        is_running=1  # not running
        docker container rm -f $container 2>/dev/null || true # remove any stopped container
    fi
}


test_if_initialized() {
    ttyopt=''; [[ -t 0 ]] && ttyopt='-T'  # autodetect tty
    if (( $is_running == 0 )); then
        docker-compose -f dc.yaml exec $ttyopt $service /scripts/is_initialized.sh
        is_init=$? # 0=init, 1=not init
    else
        docker-compose -f dc.yaml run $ttyopt --rm $service /scripts/is_initialized.sh
        is_init=$?
    fi
}


wait_for_database() {
    if (( $is_running > 0 )); then
        docker-compose -f dc.yaml run $ttyopt --rm $service bash /opt/PVZDweb/pvzdweb/wait_pg_become_ready.sh
    fi
}