pipeline {
    agent any
    environment {
        compose_cfg='docker-compose.yaml'
        compose_f_opt=''
        container='pvzdweb'
        pg_container='postgres_ci'
        pg_compose_cfg='dc_postgres.yaml'
        d_containers="${container} dc_${container}_run_1 postgres_ci ${pg_container} pvzdweb "
        d_pg_volumes='postgres_ci.data'
        d_app_volumes='pvzdweb.config pvzdweb.var_lib_git pvzdweb.var_log pvzdweb.settings'
        service='pvzdweb'
        project='jenkins'
        projopt="-p $project"
        // redundant from docker-compose (circumvent cocker-compose issued with `docker exec`):
        image='r2h2/pvzdweb'
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
                        ./dcshell/update_config.sh dc_build.yaml.default dc_build.yaml
                    else
                        cp "${compose_cfg}.default" $compose_cfg
                        cp dc_build.yaml.default dc_build.yaml
                    fi
                    cp -n config.env.default config.env
                    cp -n secrets.env.default secrets.env
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
                    remove_volumes $d_app_volumes $d_pg_volumes && echo '.'
                    cp -f config.env.default config.env
                    cp -f secrets.env.default secrets.env
                '''
            }
        }
        stage('Build') {
            steps {
                sh '''#!/bin/bash -e
                    source ./jenkins_scripts.sh
                    remove_container_if_not_running $container
                    if [[ "$nocache" ]]; then
                         nocacheopt='-c'
                         echo 'build with option nocache'
                    fi
                    export MANIFEST_SCOPE='local'
                    export PROJ_HOME='.'
                    ./dcshell/build -f dc_build.yaml $nocacheopt || \
                        (rc=$?; echo "build failed with rc rc?"; exit $rc)
                '''
            }
        }
        stage('Unittest') {
            steps {
                echo 'Run tests unless already running (keeping previously initialized data)'
                sh '''#!/bin/bash -e
                    source ./jenkins_scripts.sh
                    is_running=$(test_if_container_running $container)
                    if [[ ! "$is_running" ]]; then
                        verify_python_env $compose_cfg
                        make_postgres_running
                        export CSRFENCRYPTKEY=$(openssl rand -base64 16)
                        export CSRFSECRET=$(openssl rand -base64 16)
                        export DJANGO_SETTINGS_MODULE='pyzdwb.settings_jenkins'
                        export DJANGO_SECRET_KEY=$(openssl rand -base64 16)
                        nottyopt=''; [[ -t 0 ]] || nottyopt='-T'  # autodetect tty
                        wait_for_database
                        exec_compose "--no-ansi up -d $service" && echo ''
                        set_database_password
                        echo " running pytest_all_noninteractive.sh"
                        # docker-compose exec sometimes does not provide stdout in non-ptty mode -> use `docker exec`
                        exec_compose "exec $nottyopt $service bash -l -c /opt/PVZDweb/bin/pytest_all_noninteractive.sh"
                        exec_compose "logs $service"
                        #docker exec $container bash -l -c '/opt/PVZDweb/bin/pytest_all_noninteractive.sh'
                        exec_compose "down -v" || true
                        docker-compose $projopt -f $pg_compose_cfg down -v || true
                    fi
                '''
            }
        }
        stage('Load/Run') {
            steps {
                echo 'test webapp'
                sh '''#!/bin/bash -e
                    source ./jenkins_scripts.sh
                    make_postgres_running
                    wait_for_database
                    export DJANGO_SETTINGS_MODULE='pyzdwb.settings_jenkins'
                    export DJANGO_SECRET_KEY=$(openssl rand -base64 30)
                    exec_compose "--no-ansi up -d $container" && echo ''
                    wait_for_container_up
                    load_testdata $compose_f_opt || true # TODO: test for return code when data has been cleaned
                    exec_compose "exec $nottyopt $container bash -l -c /tests/test_webapp.sh"
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
                    remove_containers $d_containers && echo '.'
                    remove_volumes $d_volumes && echo '.'
                fi
            '''
        }
    }
}