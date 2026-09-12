pipeline {
    agent {
        label 'linux'
    }

    options {
        skipDefaultCheckout(true)
        timestamps()
        disableConcurrentBuilds()
    }

    parameters {
        choice(
            name: 'SERVICE',
            choices: [
                'auth-service',
                'student-service',
                'gateway'
            ],
            description: 'Microservice to build'
        )

        booleanParam(
            name: 'FAIL_ON_SECURITY_ISSUES',
            defaultValue: false,
            description: 'Fail pipeline when Trivy finds HIGH/CRITICAL issues'
        )
    }

    environment {
        AWS_REGION     = 'us-east-2'
        AWS_ACCOUNT_ID = '112859066474'
        ECR_REPO       = 'platform-app'

        SONAR_URL      = 'http://18.223.49.150:9000'
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Prepare') {
            steps {
                script {
                    env.IMAGE_TAG = "${params.SERVICE}-${env.BUILD_NUMBER}"

                    env.ECR_REGISTRY =
                        "${env.AWS_ACCOUNT_ID}.dkr.ecr.${env.AWS_REGION}.amazonaws.com"

                    env.IMAGE =
                        "${env.ECR_REGISTRY}/${env.ECR_REPO}:${env.IMAGE_TAG}"

                    env.LATEST_IMAGE =
                        "${env.ECR_REGISTRY}/${env.ECR_REPO}:${params.SERVICE}-latest"
                }

                sh '''
                    echo "======================================"
                    echo "BUILD INFORMATION"
                    echo "======================================"
                    echo "Agent:   $(hostname)"
                    echo "Service: ${SERVICE}"
                    echo "Build:   ${BUILD_NUMBER}"
                    echo "Image:   ${IMAGE}"
                    echo "======================================"

                    test -d "${SERVICE}"
                    test -f "${SERVICE}/package.json"
                    test -f "${SERVICE}/Dockerfile"
                '''
            }
        }

        stage('Install Dependencies') {
            steps {
                dir("${params.SERVICE}") {
                    sh '''
                        if [ -f package-lock.json ]; then
                            npm ci
                        else
                            npm install
                        fi
                    '''
                }
            }
        }

        stage('Unit Tests') {
            steps {
                dir("${params.SERVICE}") {
                    sh '''
                        npm test --if-present
                    '''
                }
            }
        }

        stage('Check SonarQube') {
            steps {
                sh '''
                    echo "Checking SonarQube..."

                    curl -fsS \
                      "${SONAR_URL}/api/system/status"

                    echo
                '''
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withCredentials([
                    string(
                        credentialsId: 'sonarqube-token',
                        variable: 'SONAR_TOKEN'
                    )
                ]) {
                    dir("${params.SERVICE}") {
                        sh '''
                            sonar-scanner \
                              -Dsonar.projectKey=physics-platform-${SERVICE} \
                              -Dsonar.projectName=physics-platform-${SERVICE} \
                              -Dsonar.sources=. \
                              -Dsonar.exclusions=node_modules/**,coverage/**,dist/** \
                              -Dsonar.host.url=${SONAR_URL} \
                              -Dsonar.token=${SONAR_TOKEN} \
                              -Dsonar.qualitygate.wait=true \
                              -Dsonar.qualitygate.timeout=300
                        '''
                    }
                }
            }
        }

        stage('Trivy Filesystem Scan') {
            steps {
                dir("${params.SERVICE}") {
                    sh '''
                        EXIT_CODE=0

                        if [ "${FAIL_ON_SECURITY_ISSUES}" = "true" ]; then
                            EXIT_CODE=1
                        fi

                        trivy fs \
                          --scanners vuln,secret,misconfig \
                          --severity HIGH,CRITICAL \
                          --skip-dirs node_modules \
                          --exit-code ${EXIT_CODE} \
                          .
                    '''
                }
            }
        }

        stage('Docker Build') {
            steps {
                dir("${params.SERVICE}") {
                    sh '''
                        docker build \
                          -t "${IMAGE}" \
                          .
                    '''
                }
            }
        }

        stage('Trivy Image Scan') {
            steps {
                sh '''
                    EXIT_CODE=0

                    if [ "${FAIL_ON_SECURITY_ISSUES}" = "true" ]; then
                        EXIT_CODE=1
                    fi

                    trivy image \
                      --severity HIGH,CRITICAL \
                      --ignore-unfixed \
                      --exit-code ${EXIT_CODE} \
                      "${IMAGE}"
                '''
            }
        }

        stage('AWS Identity') {
            steps {
                sh '''
                    aws sts get-caller-identity
                '''
            }
        }

        stage('ECR Login') {
            steps {
                sh '''
                    aws ecr get-login-password \
                      --region "${AWS_REGION}" \
                    | docker login \
                      --username AWS \
                      --password-stdin \
                      "${ECR_REGISTRY}"
                '''
            }
        }

        stage('Push to ECR') {
            steps {
                sh '''
                    docker push "${IMAGE}"

                    docker tag \
                      "${IMAGE}" \
                      "${LATEST_IMAGE}"

                    docker push "${LATEST_IMAGE}"

                    echo "======================================"
                    echo "IMAGE PUSHED"
                    echo "${IMAGE}"
                    echo "======================================"
                '''
            }
        }
    }

    post {
        success {
            echo 'CI PIPELINE SUCCESS'
            echo "Image: ${env.IMAGE}"
        }

        failure {
            echo 'CI PIPELINE FAILED'
        }

        always {
            sh '''
                if [ -n "${IMAGE:-}" ]; then
                    docker image rm "${IMAGE}" 2>/dev/null || true
                fi

                if [ -n "${LATEST_IMAGE:-}" ]; then
                    docker image rm "${LATEST_IMAGE}" 2>/dev/null || true
                fi
            '''
        }
    }
}
