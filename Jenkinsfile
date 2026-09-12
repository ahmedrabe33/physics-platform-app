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

        SONAR_URL = 'http://18.223.49.150:9000'

        GITOPS_REPO   = 'https://github.com/ahmedrabe33/physics-platform-gitops.git'
        GITOPS_BRANCH = 'main'
        GITOPS_FILE   = 'k8s/overlays/eks/kustomization.yaml'
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Prepare') {
            steps {
                sh '''
                    cat > .ci-services <<'SERVICES'
auth-service|services/auth-service|physics-auth
student-service|services/student-service|physics-student
content-service|services/content-service|physics-content
progress-service|services/progress-service|physics-progress
gateway|gateway|physics-gateway
frontend|frontend|physics-frontend
SERVICES

                    echo "======================================"
                    echo "PLATFORM BUILD"
                    echo "======================================"
                    echo "Agent: $(hostname)"
                    echo "Build: ${BUILD_NUMBER}"
                    echo
                    echo "Services:"
                    cat .ci-services
                    echo "======================================"

                    while IFS='|' read -r service path kustomize
                    do
                        echo "Validating ${service}"

                        test -d "${path}"
                        test -f "${path}/Dockerfile"

                        echo "${service} OK"
                    done < .ci-services
                '''
            }
        }

        stage('Install Dependencies') {
            steps {
                sh '''
                    while IFS='|' read -r service path kustomize
                    do
                        echo "======================================"
                        echo "DEPENDENCIES: ${service}"
                        echo "======================================"

                        if [ -f "${path}/package.json" ]; then

                            cd "${WORKSPACE}/${path}"

                            if [ -f package-lock.json ]; then
                                npm ci
                            else
                                npm install
                            fi

                            cd "${WORKSPACE}"

                        else
                            echo "No package.json"
                            echo "Skipping npm dependencies"
                        fi

                    done < .ci-services
                '''
            }
        }

        stage('Unit Tests') {
            steps {
                sh '''
                    while IFS='|' read -r service path kustomize
                    do
                        echo "======================================"
                        echo "TESTS: ${service}"
                        echo "======================================"

                        if [ -f "${path}/package.json" ]; then

                            cd "${WORKSPACE}/${path}"

                            npm test --if-present

                            cd "${WORKSPACE}"

                        else
                            echo "No package.json"
                            echo "Skipping unit tests"
                        fi

                    done < .ci-services
                '''
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
                    echo "SonarQube is UP"
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
                    sh '''
                        while IFS='|' read -r service path kustomize
                        do
                            echo "======================================"
                            echo "SONARQUBE: ${service}"
                            echo "======================================"

                            cd "${WORKSPACE}/${path}"

                            sonar-scanner \
                              -Dsonar.projectKey=physics-platform-${service} \
                              -Dsonar.projectName=physics-platform-${service} \
                              -Dsonar.sources=. \
                              -Dsonar.exclusions=node_modules/**,coverage/**,dist/**,build/** \
                              -Dsonar.host.url=${SONAR_URL} \
                              -Dsonar.token=${SONAR_TOKEN} \
                              -Dsonar.qualitygate.wait=true \
                              -Dsonar.qualitygate.timeout=300

                            cd "${WORKSPACE}"

                        done < .ci-services
                    '''
                }
            }
        }

        stage('Trivy Filesystem Scan') {
            steps {
                sh '''
                    EXIT_CODE=0

                    if [ "${FAIL_ON_SECURITY_ISSUES}" = "true" ]; then
                        EXIT_CODE=1
                    fi

                    while IFS='|' read -r service path kustomize
                    do
                        echo "======================================"
                        echo "TRIVY FILESYSTEM: ${service}"
                        echo "======================================"

                        trivy fs \
                          --scanners vuln,secret,misconfig \
                          --severity HIGH,CRITICAL \
                          --skip-dirs node_modules \
                          --exit-code ${EXIT_CODE} \
                          "${path}"

                    done < .ci-services
                '''
            }
        }

        stage('Docker Build All') {
            steps {
                sh '''
                    while IFS='|' read -r service path kustomize
                    do
                        IMAGE="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${service}-${BUILD_NUMBER}"

                        echo "======================================"
                        echo "BUILDING ${service}"
                        echo "${IMAGE}"
                        echo "======================================"

                        docker build \
                          -t "${IMAGE}" \
                          "${path}"

                    done < .ci-services
                '''
            }
        }

        stage('Trivy Image Scan') {
            steps {
                sh '''
                    EXIT_CODE=0

                    if [ "${FAIL_ON_SECURITY_ISSUES}" = "true" ]; then
                        EXIT_CODE=1
                    fi

                    while IFS='|' read -r service path kustomize
                    do
                        IMAGE="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${service}-${BUILD_NUMBER}"

                        echo "======================================"
                        echo "TRIVY IMAGE: ${service}"
                        echo "======================================"

                        trivy image \
                          --severity HIGH,CRITICAL \
                          --ignore-unfixed \
                          --exit-code ${EXIT_CODE} \
                          "${IMAGE}"

                    done < .ci-services
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
                    ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

                    aws ecr get-login-password \
                      --region "${AWS_REGION}" \
                    | docker login \
                      --username AWS \
                      --password-stdin \
                      "${ECR_REGISTRY}"
                '''
            }
        }

        stage('Push All to ECR') {
            steps {
                sh '''
                    ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

                    while IFS='|' read -r service path kustomize
                    do
                        IMAGE="${ECR_REGISTRY}/${ECR_REPO}:${service}-${BUILD_NUMBER}"
                        LATEST_IMAGE="${ECR_REGISTRY}/${ECR_REPO}:${service}-latest"

                        echo "======================================"
                        echo "PUSHING ${service}"
                        echo "======================================"

                        docker push "${IMAGE}"

                        docker tag \
                          "${IMAGE}" \
                          "${LATEST_IMAGE}"

                        docker push "${LATEST_IMAGE}"

                        echo "${IMAGE} pushed successfully"

                    done < .ci-services
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
                        echo "CLONING GITOPS REPOSITORY"
                        echo "======================================"

                        rm -rf physics-platform-gitops

                        git clone \
                          --branch "${GITOPS_BRANCH}" \
                          "${GITOPS_REPO}" \
                          physics-platform-gitops

                        cd physics-platform-gitops

                        git config user.name "Jenkins"
                        git config user.email "jenkins@physics-platform.local"

                        test -f "${GITOPS_FILE}"

                        echo "======================================"
                        echo "UPDATING ALL IMAGES"
                        echo "======================================"

                        while IFS='|' read -r service path kustomize
                        do
                            NEW_TAG="${service}-${BUILD_NUMBER}"

                            echo
                            echo "Updating ${kustomize}"
                            echo "Tag: ${NEW_TAG}"

                            sed -i \
                              "/- name: ${kustomize}$/,/newTag:/ {
                                  s|^[[:space:]]*newName:.*|    newName: ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}|
                                  s|^[[:space:]]*newTag:.*|    newTag: ${NEW_TAG}|
                              }" \
                              "${GITOPS_FILE}"

                        done < "${WORKSPACE}/.ci-services"

                        echo
                        echo "======================================"
                        echo "NEW GITOPS IMAGE CONFIGURATION"
                        echo "======================================"

                        grep -A2 -- "- name:" "${GITOPS_FILE}"

                        echo
                        echo "======================================"
                        echo "VALIDATING ALL IMAGES"
                        echo "======================================"

                        while IFS='|' read -r service path kustomize
                        do
                            NEW_TAG="${service}-${BUILD_NUMBER}"

                            grep -A2 \
                              -- "- name: ${kustomize}" \
                              "${GITOPS_FILE}" \
                              | grep -q "newName: ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}"

                            grep -A2 \
                              -- "- name: ${kustomize}" \
                              "${GITOPS_FILE}" \
                              | grep -q "newTag: ${NEW_TAG}"

                            echo "${kustomize} validated"

                        done < "${WORKSPACE}/.ci-services"

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
                          -m "Deploy platform build ${BUILD_NUMBER}"

                        echo
                        echo "Pushing GitOps commit..."

                        set +x

                        git push \
                          "https://x-access-token:${GITHUB_TOKEN}@github.com/ahmedrabe33/physics-platform-gitops.git" \
                          "${GITOPS_BRANCH}"

                        set -x

                        echo
                        echo "======================================"
                        echo "ALL GITOPS IMAGES UPDATED"
                        echo "======================================"
                    '''
                }
            }
        }
    }

    post {

        success {
            echo '======================================'
            echo 'PLATFORM CI/CD SUCCESS'
            echo '======================================'
            echo "Build: ${env.BUILD_NUMBER}"
            echo 'All six services were pushed to ECR.'
            echo 'GitOps was updated with one commit.'
            echo 'ArgoCD will deploy the new images to EKS.'
        }

        failure {
            echo '======================================'
            echo 'PLATFORM CI/CD FAILED'
            echo '======================================'
            echo "Build: ${env.BUILD_NUMBER}"
        }

        always {
            sh '''
                echo "Cleaning Docker images"

                ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

                if [ -f .ci-services ]; then

                    while IFS='|' read -r service path kustomize
                    do
                        IMAGE="${ECR_REGISTRY}/${ECR_REPO}:${service}-${BUILD_NUMBER}"
                        LATEST_IMAGE="${ECR_REGISTRY}/${ECR_REPO}:${service}-latest"

                        docker image rm "${IMAGE}" 2>/dev/null || true
                        docker image rm "${LATEST_IMAGE}" 2>/dev/null || true

                    done < .ci-services
                fi

                rm -rf physics-platform-gitops
                rm -f .ci-services
            '''
        }
    }
}
