pipeline {
    agent any
    options { disableConcurrentBuilds() }
    parameters {
        string(defaultValue: 'True', description: '"True": initial cleanup: remove container and volumes; otherwise leave empty', name: 'start_clean')
        string(description: '"True": "Set --nocache for docker build; otherwise leave empty', name: 'nocache')
        string(description: '"True": push docker image after build; otherwise leave empty', name: 'pushimage')
        string(description: '"True": keep running after test; otherwise leave empty to delete container and volumes', name: 'keep_running')
    }

    stages {
        stage('Config ') {
            steps {
                sh '''
                   if [[ "$DOCKER_REGISTRY_USER" ]]; then
                        echo "  Docker registry user: $DOCKER_REGISTRY_USER"
                        ./dcshell/update_config.sh dc.yaml.default > dc.yaml
                        ./dcshell/update_config.sh dc-setup.yaml.default > dc-setup.yaml
                    else
                        cp dc.yaml.default dc.yaml
                        cp dc-setup.yaml.default dc-setup.yaml
                    fi
                    head dc.yaml
                '''
            }
        }
        stage('Cleanup ') {
            when {
                expression { params.$start_clean?.trim() != '' }
            }
            steps {
                sh '''
                    docker-compose -f dc.yaml down -v 2>/dev/null | true
                '''
            }
        }
        stage('Build') {
            steps {
                sh '''#!/bin/bash
                    [[ "$nocache" ]] && nocacheopt='-c' && echo 'build with option nocache'
                    export MANIFEST_SCOPE='local'
                    export PROJ_HOME='.'
                    #TODO checkout pvzdlib

                    ./dcshell/build -f dc.yaml $nocacheopt
                    echo "=== build completed with rc $?"
                '''
            }
        }
        stage('Test: Setup persistent volumes, ') {
            steps {
                echo 'Setup unless already setup and running (keeping previously initialized data) '
                sh '''#!/bin/bash
                    source ./dcshell/dcshell_lib.sh
                    if [[ "$(docker ps -f name=pvzdfe |egrep -v ^CONTAINER)" ]]; then
                        is_running=0  # running
                    else
                        is_running=1  # not running
                        docker rm -f pvzdfe 2>/dev/null || true # remove any stopped container
                    fi
                    if (( $is_running == 0 )); then
                        docker-compose -f dc.yaml exec -T pvzdfe /scripts/is_initialized.sh
                        is_init=$? # 0=init, 1=not init
                    else
                        docker-compose -f dc.yaml run -T --rm pvzdfe /scripts/is_initialized.sh
                        is_init=$?
                    fi
                    if (( $is_init != 0 )); then
                        echo "setup initial database and testdata"
                        if (( $is_running == 0 )); then
                            docker-compose -f dc.yaml exec -T pvzdfe /scripts/init_data.py
                        else
                            docker-compose -f dc.yaml run -T --rm pvzdfe /scripts/init_data.py
                        fi
                        if (( $is_running == 1 )); then
                            echo "start server"
                            docker-compose -f dc.yaml up -d pvzdfe
                            sleep 2
                            echo "=== tail container log"
                            docker-compose -f dc.yaml logs pvzdfe
                            echo "==="
                        fi
                        echo "authorize backend ssh user (test key)"
                        docker-compose -f dc.yaml exec -T --user backend pvzdfe /tests/setup_backend_ssh_auth.sh
                        docker-compose -f dc.yaml exec -T --user root pvzdfe /scripts/set_initialized.sh
                    else
                        echo 'skipping - already setup'
                    fi
                '''
            }
        }
        stage('Test: run internal tests: build and run test container (99)') {
            steps {
                echo 'build test container'
                sh 'docker-compose -f dc.yaml build pvzdfe-sshtest'
                echo 'test webapp'
                sh 'docker-compose -f dc.yaml exec -T pvzdfe /tests/test_webapp.sh'
                sh '''
                    echo "test login with backend ssh key"
                    docker-compose -f dc.yaml run -T --rm pvzdfe-sshtest /tests/test_git_client.sh
                    echo "ssh login rc=$?"
                    docker-compose -f dc.yaml run -T --rm pvzdfe-sshtest cat /var/log/test_git_client.log
                '''
            }
        }
        stage('Push ') {
            when {
                expression { params.pushimage?.trim() != '' }
            }
            steps {
                sh '''
                    default_registry=$(docker info 2> /dev/null |egrep '^Registry' | awk '{print $2}')
                    echo "  Docker default registry: $default_registry"
                    export MANIFEST_SCOPE='local'
                    export PROJ_HOME='.'
                    ./dcshell/build -f dc.yaml -P
                '''
            }
        }
    }
    post {
        always {
            sh '''
                if [[ "$keep_running" ]]; then
                    echo "Keep container running"
                else
                    echo 'Remove container, volumes'
                    docker-compose -f dc.yaml rm --force -v 2>/dev/null || true
                    docker rm --force -v shibsp 2>/dev/null || true  # in case docker-compose fails ..
                fi
            '''
        }
    }
}