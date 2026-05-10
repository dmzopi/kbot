pipeline {
        agent {
        // Golang must be installed on agent host, label applied.
        label 'go'
        }

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
    }

    stages {
        /*
        // Step is skipped since project uses Pipeline script from SCM, so repo clone is done automatically.
        stage('Clone') {
            steps {
                echo 'CLONE REPOSITORY'
                git branch: "${BRANCH}", url: "${REPO}"
            }
        }
        */
        stage('PrintEnv') {
            steps {
                script {
                    echo "Cloned repo: ${env.GIT_URL}, branch: ${env.GIT_BRANCH}"
                    echo """
                        building with parameters:
                        OS          = ${params.OS}
                        ARCH        = ${params.ARCH}
                        SKIP_TESTS  = ${params.SKIP_TESTS}
                        """
                }
            }
        }
        stage('Test') {
            steps {
                script {
                    if (params.SKIP_TESTS) {
                        echo 'TEST SKIPPED'
                    } else {
                        echo 'TEST EXECUTION STARTED'
                        sh 'make test'
                    }
                }
            }
        }
        stage('Build') {
            steps {
                echo 'BUILD EXECUTION STARTED'
                sh "make build TARGETOS=${params.OS} TARGETARCH=${params.ARCH}"
            }
        }
        stage('image') {
            steps {
                echo 'BUILD IMAGE EXECUTION STARTED'
                sh 'make image'
            }
        }
        stage('push') {
            // Require Docker Pipeline plugin. Use docker.io log/pass from Credentials.
            steps {
                script {
                    docker.withRegistry('', 'docker_hub_repo') {
                        sh 'make push'
                    }
                }
            }
        }
    }
}