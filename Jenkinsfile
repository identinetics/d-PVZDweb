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
                        ./dcshell/update_config.sh dc_webapps.yaml.default dc.yaml
                    else
                        cp dc_webapps.yaml.default dc.yaml
                    fi
                    head -6 dc.yaml | tail -1
                '''
            }
        }
        stage('Cleanup ') {
            when {
                expression { params.$start_clean?.trim() != '' }
            }
            steps {
                sh '''#!/bin/bash
                    source ./jenkins_scripts.sh
                    remove_containers
                    remove_volumes
                '''
            }
        }
        stage('Build') {
            steps {
                sh '''#!/bin/bash
                    [[ "$nocache" ]] && nocacheopt='-c' && echo 'build with option nocache'
                    export MANIFEST_SCOPE='local'
                    export PROJ_HOME='.'
                    ./dcshell/build -f dc.yaml $nocacheopt || \
                        (rc=$?; echo "build failed with rc rc?"; exit $rc)
                '''
            }
        }
        stage('Test: setup') {
            steps {
                echo 'Setup unless already setup and running (keeping previously initialized data) '
                sh '''#!/bin/bash
                    source jenkins_scripts.sh
                    create_network_dfrontend
                    docker-compose -f dc_postgres.yaml up -d
                    service=mdreg
                    container='mdreg'
                    test_if_running
                    test_if_initialized
                    if (( $is_init != 0 )); then
                        wait_pg_become_ready.sh
                        load_testdata
                        if (( $is_running == 1 )); then
                            echo "start server"
                            docker-compose -f dc.yaml up -d $service && sleep 2
                            docker-compose -f dc.yaml logs $service
                            echo "==="
                        fi
                    else
                        echo 'skipping - already setup'
                    fi
                '''
            }
        }
        stage('Test: run ') {
            steps {
                echo 'test webapp'
                sh 'docker-compose -f dc.yaml exec -T mdreg /tests/test_webapp.sh'
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
            sh '''#!/bin/bash
                if [[ "$keep_running" ]]; then
                    echo "Keep container running"
                else
                    source ./jenkins_scripts.sh
                    remove_containers
                    remove_volumes
                fi
            '''
        }
    }
}