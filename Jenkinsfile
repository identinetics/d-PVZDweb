pipeline {
    agent any
    environment {
        compose_cfg='docker-compose.yaml'
        compose_f_opt=''
        container='allapps'
        pg_container='postgres_ci'
        d_containers="${container} dc_${container}_run_1 postgres_ci ${pg_container} fedop portaladmin tnadmin"
        d_volumes='postgres_ci.data pvzdweb.config pvzdweb.var_lib_git pvzdweb.var_log pvzdweb.settings'
        service='allapps'
        projopt='-p jenkins'
    }
    options { disableConcurrentBuilds() }
    parameters {
        string(defaultValue: 'True', description: '"True": initial cleanup: remove container and volumes; otherwise leave empty', name: 'start_clean')
        string(defaultValue: '', description: '"True": "Set --nocache for docker build; otherwise leave empty', name: 'nocache')
        string(defaultValue: '', description: '"True": push docker image after build; otherwise leave empty', name: 'pushimage')
        string(defaultValue: '', description: '"True": keep running after test; otherwise leave empty to delete container and volumes', name: 'keep_running')
    }

    stages {
        stage('Config ') {
            steps {
                sh '''#!/bin/bash -e
                    echo "using ${compose_cfg} as docker-compose config file"
                    if [[ "$DOCKER_REGISTRY_USER" ]]; then
                        echo "  Docker registry user: $DOCKER_REGISTRY_USER"
                        ./dcshell/update_config.sh "${compose_cfg}.default" $compose_cfg
                    else
                        cp "${compose_cfg}.default" $compose_cfg
                    fi
                    egrep '( image:| container_name:)' $compose_cfg || echo "missing keys in ${compose_cfg}"
                '''
            }
        }
        stage('Cleanup ') {
            when {
                expression { params.$start_clean?.trim() != '' }
            }
            steps {
                sh '''#!/bin/bash -e
                    source ./jenkins_scripts.sh
                    remove_containers $d_containers && echo '.'
                    remove_volumes $d_volumes && echo '.'
                '''
            }
        }
        stage('Build') {
            steps {
                sh '''#!/bin/bash -e
                    source ./jenkins_scripts.sh
                    remove_container_if_not_running
                    if [[ "$nocache" ]]; then
                         nocacheopt='-c'
                         echo 'build with option nocache'
                    fi
                    export MANIFEST_SCOPE='local'
                    export PROJ_HOME='.'
                    ./dcshell/build $compose_f_opt $nocacheopt || \
                        (rc=$?; echo "build failed with rc rc?"; exit $rc)
                '''
            }
        }
        stage('Test: setup') {
            steps {
                echo 'Setup unless already setup and running (keeping previously initialized data) '
                sh '''#!/bin/bash -e
                    source ./jenkins_scripts.sh
                    is_running=$(test_if_running $container)
                    if [[ ! "$is_running" ]]; then
                        verify_python_env $compose_cfg
                        make_postgres_running
                        wait_for_database $compose_f_opt
                        load_testdata $compose_f_opt
                        echo "start server"
                        docker-compose $projop $compose_f_opt --no-ansi up -d tnadmin && echo ''
                    elif [[ ! "$start_clean" ]]; then
                        echo 'container already running: restart using the existing volumes'
                        docker-compose $projop $compose_f_opt down
                        docker-compose $projop $compose_f_opt --no-ansi up -d tnadmin && echo ''
                    fi
                    wait_for_container_up tnadmin
                '''
            }
        }
        stage('Test: run') {
            steps {
                echo 'test webapp'
                sh '''#!/bin/bash -e
                    nottyopt=''; [[ -t 0 ]] || nottyopt='-T'  # autodetect tty
                    cmd="docker-compose $projop $compose_f_opt exec $nottyopt tnadmin /tests/test_webapp.sh"
                    echo $cmd; $cmd || rc=$?
                    if ((rc==0)); then
                        echo "test OK"
                    else
                        echo "test failed"
                        exit 1
                    fi
                '''
            }
        }
        stage('Push ') {
            when {
                expression { params.pushimage?.trim() != '' }
            }
            steps {
                sh '''#!/bin/bash -e
                    default_registry=$(docker info 2> /dev/null |egrep '^Registry' | awk '{print $2}')
                    echo "  Docker default registry: $default_registry"
                    export MANIFEST_SCOPE='local'
                    export PROJ_HOME='.'
                    ./dcshell/build $compose_f_opt -P
                '''
            }
        }
    }
    post {
        always {
            sh '''#!/bin/bash -e
                if [[ "$keep_running" ]]; then
                    echo "Keep container running"
                else
                    source ./jenkins_scripts.sh
                    remove_containers $d_containers && echo 'containers removed'
                    remove_volumes $d_volumes && echo 'volumes removed'
                fi
            '''
        }
    }
}