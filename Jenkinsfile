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

                    /*
                     * First webhook build can sometimes run
                     * before Jenkins initializes parameters.
                     */
                    env.SERVICE = params.SERVICE?.trim()

                    if (!env.SERVICE) {
                        env.SERVICE = 'auth-service'
                    }

                    /*
                     * Repository paths
                     */
                    switch (env.SERVICE) {

                        case 'auth-service':
                            env.SERVICE_PATH = 'services/auth-service'
                            break

                        case 'student-service':
                            env.SERVICE_PATH = 'services/student-service'
                            break

                        case 'gateway':
                            env.SERVICE_PATH = 'gateway'
                            break

                        default:
                            error("Unsupported service: ${env.SERVICE}")
                    }

                    /*
                     * ECR image information
                     */
                    env.IMAGE_TAG =
                        "${env.SERVICE}-${env.BUILD_NUMBER}"

                    env.ECR_REGISTRY =
                        "${env.AWS_ACCOUNT_ID}.dkr.ecr.${env.AWS_REGION}.amazonaws.com"

                    env.IMAGE =
                        "${env.ECR_REGISTRY}/${env.ECR_REPO}:${env.IMAGE_TAG}"

                    env.LATEST_IMAGE =
                        "${env.ECR_REGISTRY}/${env.ECR_REPO}:${env.SERVICE}-latest"
                }

                sh '''
                    echo "======================================"
                    echo "BUILD INFORMATION"
                    echo "======================================"

                    echo "Agent:        $(hostname)"
                    echo "Service:      ${SERVICE}"
                    echo "Service Path: ${SERVICE_PATH}"
                    echo "Build:        ${BUILD_NUMBER}"
                    echo "Image Tag:    ${IMAGE_TAG}"
                    echo "Image:        ${IMAGE}"

                    echo "======================================"
                    echo "VALIDATING SERVICE"
                    echo "======================================"

                    test -d "${SERVICE_PATH}"

                    test -f "${SERVICE_PATH}/package.json"

                    test -f "${SERVICE_PATH}/Dockerfile"

                    echo "Service validation successful"
                '''
            }
        }

        stage('Install Dependencies') {
            steps {
                dir("${env.SERVICE_PATH}") {
                    sh '''
                        echo "Installing dependencies for ${SERVICE}"

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
                dir("${env.SERVICE_PATH}") {
                    sh '''
                        echo "Running tests for ${SERVICE}"

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
                    echo "SonarQube is reachable"
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

                    dir("${env.SERVICE_PATH}") {

                        sh '''
                            echo "Running SonarQube analysis"

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
                dir("${env.SERVICE_PATH}") {

                    sh '''
                        echo "Running Trivy filesystem scan"

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
                dir("${env.SERVICE_PATH}") {

                    sh '''
                        echo "======================================"
                        echo "BUILDING DOCKER IMAGE"
                        echo "======================================"

                        echo "${IMAGE}"

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
                    echo "Running Trivy image scan"

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
                    echo "======================================"
                    echo "AWS IDENTITY"
                    echo "======================================"

                    aws sts get-caller-identity
                '''
            }
        }

        stage('ECR Login') {
            steps {

                sh '''
                    echo "Logging into ECR"

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
                    echo "======================================"
                    echo "PUSHING IMAGE TO ECR"
                    echo "======================================"

                    docker push "${IMAGE}"

                    docker tag \
                      "${IMAGE}" \
                      "${LATEST_IMAGE}"

                    docker push "${LATEST_IMAGE}"

                    echo
                    echo "======================================"
                    echo "IMAGE PUSHED SUCCESSFULLY"
                    echo "======================================"

                    echo "Version:"
                    echo "${IMAGE}"

                    echo
                    echo "Latest:"
                    echo "${LATEST_IMAGE}"
                '''
            }
        }
    }

    post {

        success {
            echo '======================================'
            echo 'CI PIPELINE SUCCESS'
            echo '======================================'

            echo "Service: ${env.SERVICE}"
            echo "Image: ${env.IMAGE}"
        }

        failure {
            echo '======================================'
            echo 'CI PIPELINE FAILED'
            echo '======================================'

            echo "Service: ${env.SERVICE ?: 'unknown'}"
        }

        always {

            sh '''
                echo "Cleaning local Docker images"

                if [ -n "${IMAGE:-}" ]; then
                    docker image rm \
                      "${IMAGE}" \
                      2>/dev/null || true
                fi

                if [ -n "${LATEST_IMAGE:-}" ]; then
                    docker image rm \
                      "${LATEST_IMAGE}" \
                      2>/dev/null || true
                fi
            '''
        }
    }
}

بعدها:
