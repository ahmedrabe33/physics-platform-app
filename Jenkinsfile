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

        GITOPS_REPO    = 'https://github.com/ahmedrabe33/physics-platform-gitops.git'
        GITOPS_BRANCH  = 'main'
        GITOPS_FILE    = 'k8s/overlays/eks/kustomization.yaml'
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
                    env.SERVICE = params.SERVICE?.trim()

                    if (!env.SERVICE) {
                        env.SERVICE = 'auth-service'
                    }

                    switch (env.SERVICE) {

                        case 'auth-service':
                            env.SERVICE_PATH = 'services/auth-service'
                            env.KUSTOMIZE_IMAGE = 'physics-auth'
                            break

                        case 'student-service':
                            env.SERVICE_PATH = 'services/student-service'
                            env.KUSTOMIZE_IMAGE = 'physics-student'
                            break

                        case 'gateway':
                            env.SERVICE_PATH = 'gateway'
                            env.KUSTOMIZE_IMAGE = 'physics-gateway'
                            break

                        default:
                            error("Unsupported service: ${env.SERVICE}")
                    }

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

                    echo "Agent:           $(hostname)"
                    echo "Service:         ${SERVICE}"
                    echo "Service Path:    ${SERVICE_PATH}"
                    echo "Kustomize Image: ${KUSTOMIZE_IMAGE}"
                    echo "Build:           ${BUILD_NUMBER}"
                    echo "Image Tag:       ${IMAGE_TAG}"
                    echo "Image:           ${IMAGE}"

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

                    curl \
                      --fail \
                      --silent \
                      --show-error \
                      --connect-timeout 10 \
                      --max-time 30 \
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
                            echo "Running SonarQube analysis for ${SERVICE}"

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
                    echo "Logging into Amazon ECR"

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

        stage('Update GitOps') {
            steps {
                withCredentials([
                    string(
                        credentialsId: 'github-token',
                        variable: 'GITHUB_TOKEN'
                    )
                ]) {
                    sh '''
                        echo "======================================"
                        echo "UPDATING GITOPS REPOSITORY"
                        echo "======================================"

                        rm -rf physics-platform-gitops

                        set +x

                        git clone \
                          --branch "${GITOPS_BRANCH}" \
                          "https://x-access-token:${GITHUB_TOKEN}@github.com/ahmedrabe33/physics-platform-gitops.git" \
                          physics-platform-gitops

                        set -x

                        cd physics-platform-gitops

                        git config user.name "Jenkins"
                        git config user.email "jenkins@physics-platform.local"

                        echo "Service:         ${SERVICE}"
                        echo "Kustomize Image: ${KUSTOMIZE_IMAGE}"
                        echo "New Name:        ${ECR_REGISTRY}/${ECR_REPO}"
                        echo "New Tag:         ${IMAGE_TAG}"

                        test -f "${GITOPS_FILE}"

                        sed -i \
                          "/- name: ${KUSTOMIZE_IMAGE}$/,/newTag:/ {
                              s|^[[:space:]]*newName:.*|    newName: ${ECR_REGISTRY}/${ECR_REPO}|
                              s|^[[:space:]]*newTag:.*|    newTag: ${IMAGE_TAG}|
                          }" \
                          "${GITOPS_FILE}"

                        echo
                        echo "======================================"
                        echo "UPDATED KUSTOMIZE IMAGE"
                        echo "======================================"

                        grep -A2 \
                          -- "- name: ${KUSTOMIZE_IMAGE}" \
                          "${GITOPS_FILE}"

                        echo
                        echo "======================================"
                        echo "VALIDATING UPDATE"
                        echo "======================================"

                        grep -A2 \
                          -- "- name: ${KUSTOMIZE_IMAGE}" \
                          "${GITOPS_FILE}" \
                          | grep -q "newName: ${ECR_REGISTRY}/${ECR_REPO}"

                        grep -A2 \
                          -- "- name: ${KUSTOMIZE_IMAGE}" \
                          "${GITOPS_FILE}" \
                          | grep -q "newTag: ${IMAGE_TAG}"

                        git add "${GITOPS_FILE}"

                        if git diff --cached --quiet; then
                            echo "No GitOps changes detected"
                            exit 0
                        fi

                        echo
                        echo "======================================"
                        echo "GITOPS DIFF"
                        echo "======================================"

                        git diff --cached

                        git commit \
                          -m "Deploy ${SERVICE} ${IMAGE_TAG}"

                        echo
                        echo "Pushing GitOps commit..."

                        set +x

                        git push origin "${GITOPS_BRANCH}"

                        set -x

                        echo
                        echo "======================================"
                        echo "GITOPS UPDATE PUSHED SUCCESSFULLY"
                        echo "======================================"
                    '''
                }
            }
        }
    }

    post {

        success {
            echo '======================================'
            echo 'CI/CD PIPELINE SUCCESS'
            echo '======================================'

            echo "Service: ${env.SERVICE}"
            echo "Image: ${env.IMAGE}"
            echo "GitOps image: ${env.KUSTOMIZE_IMAGE}"
            echo 'ArgoCD will detect the GitOps commit and sync EKS.'
        }

        failure {
            echo '======================================'
            echo 'CI/CD PIPELINE FAILED'
            echo '======================================'

            echo "Service: ${env.SERVICE ?: 'unknown'}"
        }

        always {
            sh '''
                echo "Cleaning workspace resources"

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

                rm -rf physics-platform-gitops
            '''
        }
    }
}
