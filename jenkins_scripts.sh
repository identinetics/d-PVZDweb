#!/usr/bin/env bash


remove_containers() {
    for cont in 'pvzdweb' 'postgres'; do
        container_found=$(docker container ls --format '{{.Names}}' | grep ^$cont$)
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


create_network_dfrontend() {
    nw='dfrontend'
    network_found=$(docker network ls | grep $nw)
    if [[ ! "$network_found" ]]; then
        docker network create --driver bridge --subnet=10.1.2.0/24 \
            -o com.docker.network.bridge.name=br-$nw $nw
    fi
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
    if (( $is_running == 0 )); then
        docker-compose -f dc.yaml exec -T $service /scripts/is_initialized.sh
        is_init=$? # 0=init, 1=not init
    else
        docker-compose -f dc.yaml run -T --rm $service /scripts/is_initialized.sh
        is_init=$?
    fi
}


load_testdata() {
    echo "set database credentials for CLi client"
    echo "load initial testdata"
    if (( $is_running == 0 )); then
        docker-compose -f dc.yaml exec -T $service /scripts/init_data.py
    else
        docker-compose -f dc.yaml run -T --rm $service /scripts/init_data.py
    fi
}

