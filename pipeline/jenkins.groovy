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
        booleanParam(
            name: 'SKIP_LINT',
            defaultValue: false,
            description: 'Skip running linter'
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
                echo 'Cloned repo: $GIT_URL, branch: $GIT_BRANCH'
                echo 'Building with parameters: '
                echo 'OS=${params.OS}\nARCH=${params.ARCH}\nSKIP_TESTS=${params.SKIP_TESTS}\nSKIP_LINT=${params.SKIP_LINT}'

            }
        }
        stage('Test') {
            steps {
                if (params.SKIP_TESTS) {
                    echo 'Skipping tests'
                } else {
                    echo 'TEST EXECUTION STARTED'
                    sh 'make test'
                }
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
