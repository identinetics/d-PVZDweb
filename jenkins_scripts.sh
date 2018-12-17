#!/usr/bin/env bash


remove_containers() {
    for cont in 'pvzdweb' 'postgres' 'pvzdweb-sshtest'; do
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
               'pvzdweb-sshtest.log' \
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
