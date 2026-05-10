pipeline {
    agent any
    
    parameters {
        choice(
            name: 'OS',
            choices: ['linux', 'darwin', 'windows'],
            description: 'Target operating system'
        )
        choice(
            name: 'ARCH',
            choices: ['amd64', 'arm64'],
            description: 'Target architecture'
        )
        booleanParam(
            name: 'SKIP_TESTS',
            defaultValue: false,
            description: 'Skip running tests'
        )
        booleanParam(
            name: 'SKIP_LINT',
            defaultValue: false,
            description: 'Skip running linter'
        )
    }

    stages {
        stage('Clone') {
            steps {
                echo 'CLONE REPOSITORY'
                git branch: "${BRANCH}", url: "${REPO}"
            }
        }

        stage('Test') {
            steps {
                echo 'TEST EXECUTIO STARTED'
                sh 'make test'
        }
        }

        stage('Build') {
            steps {
                echo 'BUILD EXECUTION STARTED'
                sh 'make build'
        }
        }

        stage('image') {
            steps {
                echo 'BUILD IMAGE EXECUTION STARTED'
                sh 'make image'
        }
    }
        stage('push') {
            steps {
                script {
                    docker.withRegistry( '', 'docker_hub_repo') {
                        sh 'make push'
                    }
                }

        }
    }

}