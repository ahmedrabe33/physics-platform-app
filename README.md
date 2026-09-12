⚛️ Physics Learning Platform

A production-oriented, cloud-native learning platform for Egyptian secondary-school physics, built with Node.js microservices, a web frontend, a Flutter mobile app, PostgreSQL, Docker, Kubernetes, Jenkins, GitHub Actions, Trivy, SonarQube, Amazon ECR, and GitOps with Argo CD.

📌 Overview

The Physics Learning Platform is designed as both a real educational product and a hands-on DevOps project. It has two user-facing clients:

Web Frontend — browser-based interface.

Flutter Mobile App — Android/mobile client.

Both clients consume the same backend through the API Gateway, which routes requests to independent microservices.

✨ Main Features

Students

Create an account

Select an educational grade

Upload payment proof

Wait for administrator approval

Access educational content after activation

Browse chapters and lessons

Solve exercises

Track lesson progress

Unlock lessons sequentially

Renew expired subscriptions

Administrators

Review registrations

Approve or reject students

Renew subscriptions

Add chapters

Add lessons

Add exercises

Manage educational content

🏗️ Platform Architecture

flowchart TD
    USER[Users]

    USER --> WEB[Web Frontend<br/>Browser / EJS]
    USER --> MOBILE[Flutter Mobile App<br/>Android]

    WEB --> ALB[Public Entry Point / ALB]
    MOBILE --> ALB

    ALB -->|/| FE[Frontend Service<br/>:3000]
    ALB -->|/api/*| GW[API Gateway<br/>:8080]

    FE --> GW

    GW --> AUTH[Auth Service<br/>:3001]
    GW --> STUDENT[Student Service<br/>:3002]
    GW --> CONTENT[Content Service<br/>:3003]
    GW --> PROGRESS[Progress Service<br/>:3004]

    AUTH --> DB[(PostgreSQL<br/>:5432)]
    STUDENT --> DB
    CONTENT --> DB
    PROGRESS --> DB

    STUDENT --> UPLOADS[(Persistent Upload Storage)]

Request Flow

Browser
   │
   ├── /        → Web Frontend
   │
   └── /api/*   → API Gateway
                     │
                     ├── Auth Service
                     ├── Student Service
                     ├── Content Service
                     └── Progress Service

Flutter Mobile App
   │
   └── /api/*   → API Gateway
                     │
                     ├── Auth Service
                     ├── Student Service
                     ├── Content Service
                     └── Progress Service

The browser and Flutter app share the same backend API and business logic.

🧩 Microservices

Component

Port

Responsibility

Web Frontend

3000

Browser UI and web sessions

API Gateway

8080

Routes API traffic to backend services

Auth Service

3001

Authentication and user management

Student Service

3002

Student profiles, subscriptions, and payments

Content Service

3003

Chapters, lessons, and exercises

Progress Service

3004

Student progress and lesson unlocking

PostgreSQL

5432

Persistent relational database

Flutter App

—

Native mobile client consuming /api/*

🛠️ Technology Stack

Application

Node.js

Express.js

EJS

Axios

Multer

PostgreSQL

Flutter

Dart

Containers

Docker

Docker Compose

Multi-stage builds

Alpine-based images

Non-root containers

.dockerignore

Kubernetes

Deployments

StatefulSets

Services

Ingress

ConfigMaps

Secrets

PersistentVolumeClaims

StorageClasses

Init Containers

Startup Probes

Readiness Probes

Liveness Probes

Resource Requests & Limits

Rolling Updates

CI/CD & Security

Jenkins

GitHub Actions

SonarQube

Trivy

Amazon ECR

Argo CD

GitOps

AWS CLI

Infrastructure

AWS

Amazon EKS

EC2

ECR

EBS

Application Load Balancer

IAM

Terraform

Ansible

📂 Application Repository Structure

physics-platform/
│
├── frontend/
│   ├── Dockerfile
│   ├── package.json
│   ├── server.js
│   ├── public/
│   └── views/
│
├── gateway/
│   ├── Dockerfile
│   ├── package.json
│   └── server.js
│
├── services/
│   ├── auth-service/
│   │   ├── Dockerfile
│   │   ├── package.json
│   │   └── server.js
│   ├── student-service/
│   │   ├── Dockerfile
│   │   ├── package.json
│   │   ├── server.js
│   │   └── uploads/
│   ├── content-service/
│   │   ├── Dockerfile
│   │   ├── package.json
│   │   └── server.js
│   └── progress-service/
│       ├── Dockerfile
│       ├── package.json
│       └── server.js
│
├── k8s/
│   ├── auth/
│   ├── student/
│   ├── content/
│   ├── progress/
│   ├── gateway/
│   ├── frontend/
│   ├── postgres/
│   ├── config/
│   └── ingress/
│
├── docker-compose.yml
├── Jenkinsfile
├── health.sh
├── start-all.sh
├── stop-all.sh
└── README.md

The Flutter client is part of the same platform but follows its own mobile CI/CD lifecycle through GitHub Actions.

🔁 Application Flow

flowchart TD
    A[Student Signup] --> B[Upload Payment Proof]
    B --> C[Pending Approval]
    C --> D[Admin Review]
    D -->|Reject| E[Rejected]
    D -->|Approve| F[Subscription Active]
    F --> G[Grade]
    G --> H[Chapter]
    H --> I[Lesson]
    I --> J[Exercises]
    J --> K[Complete Lesson]
    K --> L[Unlock Next Lesson]

🐳 Docker

Each backend service and the web frontend has its own Docker image.

The Dockerfiles follow practices such as:

Lightweight base images

Production-only dependencies

Multi-stage builds where appropriate

Non-root users

Reduced Linux capabilities

Health checks

.dockerignore

Docker Compose

docker compose up -d --build

docker compose ps

docker compose logs -f

docker compose down

Web frontend:

http://localhost:3000

☸️ Kubernetes

The application can run locally on Kubernetes or in AWS EKS.

Configuration

Non-sensitive configuration is stored in ConfigMaps.

apiVersion: v1
kind: ConfigMap
metadata:
  name: physics-config
  namespace: physics

data:
  NODE_ENV: production
  DB_HOST: postgres
  DB_PORT: "5432"
  AUTH_SERVICE: http://auth-service:3001
  STUDENT_SERVICE: http://student-service:3002
  CONTENT_SERVICE: http://content-service:3003
  PROGRESS_SERVICE: http://progress-service:3004
  GATEWAY_URL: http://gateway:8080

Secrets

Sensitive values are supplied through Kubernetes Secrets.

apiVersion: v1
kind: Secret
metadata:
  name: physics-secrets
  namespace: physics

type: Opaque

stringData:
  POSTGRES_USER: physics_user
  POSTGRES_PASSWORD: CHANGE_ME
  POSTGRES_DB: physics_db
  JWT_SECRET: CHANGE_ME
  SESSION_SECRET: CHANGE_ME

Never commit real production credentials to a public repository.

PostgreSQL & Persistent Storage

PostgreSQL StatefulSet
        │
        ▼
PersistentVolumeClaim
        │
        ▼
PersistentVolume
        │
        ▼
StorageClass

Student payment screenshots are also stored on persistent storage:

Student Pod
    │
    ▼
/app/uploads
    │
    ▼
PersistentVolumeClaim

Stateless vs Stateful

Stateless workloads:

Auth Service
Content Service
Progress Service
Gateway
Web Frontend

Stateful workloads:

PostgreSQL
Student upload storage

Rolling Updates

strategy:
  type: RollingUpdate
  rollingUpdate:
    maxUnavailable: 0
    maxSurge: 1

Health Probes

Services expose health endpoints such as:

/health

Kubernetes uses startup, readiness, and liveness probes.

Resource Management

resources:
  requests:
    cpu: "50m"
    memory: "64Mi"
  limits:
    cpu: "250m"
    memory: "256Mi"

Container Security

securityContext:
  runAsNonRoot: true
  runAsUser: 100
  runAsGroup: 101
  allowPrivilegeEscalation: false
  capabilities:
    drop:
      - ALL

Networking

Frontend
   ↓
Gateway
   ├── auth-service
   ├── student-service
   ├── content-service
   └── progress-service

Internal DNS examples:

http://auth-service:3001
http://student-service:3002
http://content-service:3003
http://progress-service:3004
http://postgres:5432

No backend microservice requires direct public exposure.

☁️ Production Deployment Model

flowchart TD
    INTERNET[Internet Users] --> ALB[AWS Application Load Balancer]
    ALB -->|/| WEB[Web Frontend Service]
    ALB -->|/api/*| GATEWAY[API Gateway Service]
    MOBILE[Flutter Mobile App] -->|HTTPS /api/*| ALB
    GATEWAY --> AUTH[Auth]
    GATEWAY --> STUDENT[Student]
    GATEWAY --> CONTENT[Content]
    GATEWAY --> PROGRESS[Progress]
    AUTH --> PG[(PostgreSQL)]
    STUDENT --> PG
    CONTENT --> PG
    PROGRESS --> PG

Production responsibilities are separated:

Terraform provisions AWS infrastructure.

Ansible configures servers such as Jenkins.

Jenkins handles web/backend CI/CD.

GitHub Actions handles Flutter CI/CD.

Argo CD deploys Kubernetes workloads from GitOps state.

🚀 CI/CD Overview

There are two independent pipelines.

flowchart LR
    subgraph Web_Backend[Web + Backend Pipeline]
        G1[GitHub] --> J[Jenkins]
        J --> TEST[Tests]
        TEST --> SONAR[SonarQube]
        SONAR --> TRIVY[Trivy]
        TRIVY --> DOCKER[Docker Build]
        DOCKER --> ECR[Amazon ECR]
        ECR --> GITOPS[GitOps Repo]
        GITOPS --> ARGO[Argo CD]
        ARGO --> EKS[EKS]
    end

    subgraph Mobile[Flutter Mobile Pipeline]
        G2[GitHub] --> GHA[GitHub Actions]
        GHA --> ANALYZE[flutter analyze]
        ANALYZE --> FTEST[flutter test]
        FTEST --> BUILD[Build APK/AAB]
        BUILD --> SIGN[Signing]
        SIGN --> ARTIFACT[Artifacts / Release]
    end

🟦 Web & Backend CI/CD — Jenkins

The Jenkins Declarative Pipeline builds, tests, scans, publishes, and promotes all six web/backend components.

Jenkins agent label:

linux

Pipeline behavior includes:

timestamps()

disableConcurrentBuilds()

skipDefaultCheckout(true)

Optional failure on HIGH/CRITICAL security findings

Security gate parameter:

FAIL_ON_SECURITY_ISSUES

Jenkins Pipeline Stages

#

Stage

Purpose

1

Checkout

Pull application source

2

Prepare

Build and validate the service matrix

3

Install Dependencies

npm ci or npm install

4

Unit Tests

npm test --if-present

5

Check SonarQube

Verify SonarQube availability

6

SonarQube Analysis

Static analysis + Quality Gate

7

Trivy Filesystem Scan

Vulnerability, secret, and misconfiguration scan

8

Docker Build All

Build all service images

9

Trivy Image Scan

Scan built images

10

AWS Identity

Verify Jenkins AWS identity

11

ECR Login

Authenticate Docker to ECR

12

Push All to ECR

Publish images

13

Update GitOps

Update Kustomize image tags

14

Post Actions

Cleanup and success/failure reporting

Jenkins Service Matrix

Service

Source Path

Kustomize Image

auth-service

services/auth-service

physics-auth

student-service

services/student-service

physics-student

content-service

services/content-service

physics-content

progress-service

services/progress-service

physics-progress

gateway

gateway

physics-gateway

frontend

frontend

physics-frontend

SonarQube

Each service is scanned independently.

physics-platform-<service>

sonar-scanner \
  -Dsonar.projectKey=physics-platform-${service} \
  -Dsonar.projectName=physics-platform-${service} \
  -Dsonar.sources=. \
  -Dsonar.exclusions=node_modules/**,coverage/**,dist/**,build/** \
  -Dsonar.qualitygate.wait=true \
  -Dsonar.qualitygate.timeout=300

Trivy

Filesystem scan:

trivy fs \
  --scanners vuln,secret,misconfig \
  --severity HIGH,CRITICAL \
  --skip-dirs node_modules \
  <service-path>

Image scan:

trivy image \
  --severity HIGH,CRITICAL \
  --ignore-unfixed \
  <image>

Docker Image Strategy

Current Jenkinsfile tagging:

<service>-<BUILD_NUMBER>
<service>-latest

For production, immutable Git SHA tags are preferred:

<service>-<GIT_SHA>

Amazon ECR

aws sts get-caller-identity

aws ecr get-login-password \
  --region "${AWS_REGION}" \
| docker login \
  --username AWS \
  --password-stdin \
  "${ECR_REGISTRY}"

GitOps Deployment

GitOps repository:

https://github.com/ahmedrabe33/physics-platform-gitops.git

Branch:

main

Kustomize deployment file:

k8s/overlays/eks/kustomization.yaml

Jenkins
   │
   ├── Test
   ├── SonarQube
   ├── Trivy
   ├── Docker Build
   └── Push to ECR
           │
           ▼
      GitOps Update
           │
           ▼
        Argo CD
           │
           ▼
          EKS

Jenkins does not need to deploy directly with kubectl; it updates GitOps state and Argo CD reconciles the cluster.

Jenkins Credentials

Credentials ID

Type

Purpose

sonarqube-token

Secret text

SonarQube authentication

github-token

Secret text / GitHub credential

Push GitOps updates

AWS authentication should come from the Jenkins EC2 IAM role instead of static AWS access keys.

📱 Flutter Mobile CI/CD — GitHub Actions

The Flutter application has its own pipeline independent from Jenkins.

It uses a GitHub-hosted runner, so no dedicated mobile EC2 runner is required.

runs-on: ubuntu-latest

Flutter Pipeline Architecture

flowchart TD
    PUSH[Push / Pull Request] --> CHECKOUT[Checkout]
    CHECKOUT --> FLUTTER[Setup Flutter]
    FLUTTER --> DEPS[flutter pub get]
    DEPS --> FORMAT[Format Check]
    FORMAT --> ANALYZE[flutter analyze]
    ANALYZE --> TEST[flutter test]
    TEST --> BUILD[Release Build]
    BUILD --> SIGN[Android Signing]
    SIGN --> AAB[AAB / APK]
    AAB --> ARTIFACT[GitHub Artifact]
    ARTIFACT --> RELEASE[Release / Store Promotion]

Recommended Mobile CI Stages

#

Stage

Purpose

1

Checkout

Checkout source

2

Setup Java

Install the required JDK

3

Setup Flutter

Pin Flutter version

4

Dependencies

flutter pub get

5

Formatting

dart format --output=none --set-exit-if-changed .

6

Static Analysis

flutter analyze

7

Tests

flutter test

8

Build

Build release APK/AAB

9

Signing

Restore keystore from GitHub Secrets

10

Artifact

Upload signed artifact

11

Release

Optional GitHub Release / Play Store promotion

Quality gates:

flutter pub get

dart format \
  --output=none \
  --set-exit-if-changed .

flutter analyze
flutter test

Release build:

flutter build appbundle --release

Optional APK:

flutter build apk --release

Mobile Secrets

Keep signing material in GitHub Actions Secrets:

ANDROID_KEYSTORE_BASE64
ANDROID_KEY_ALIAS
ANDROID_KEY_PASSWORD
ANDROID_STORE_PASSWORD

Never commit the production keystore to Git.

Mobile Release Strategy

Feature Branch
     │
     ▼
Pull Request
     │
     ├── Format
     ├── Analyze
     └── Test
     │
     ▼
Main
     │
     ├── Full CI
     └── Release Build
     │
     ▼
Signed AAB
     │
     ▼
Internal / Staging Testing
     │
     ▼
Manual Approval
     │
     ▼
Production

🔐 CI/CD Security Model

Jenkins EC2
   │
   ├── IAM Role → AWS / ECR permissions
   ├── Jenkins Credentials → GitHub / SonarQube
   └── No direct application secrets in Jenkinsfile

GitHub Actions
   │
   ├── GitHub Secrets → Mobile signing material
   └── Ephemeral GitHub-hosted runner

Argo CD
   │
   └── GitOps repository → Kubernetes desired state

Recommended principles:

Least-privilege IAM

No AWS keys hardcoded in Jenkins

No mobile signing credentials committed to Git

Immutable production image tags

Security scans before image promotion

SonarQube Quality Gate before deployment

GitOps as the Kubernetes deployment path

Manual approval before production mobile release

🔄 Complete Delivery Architecture

flowchart TB
    DEV[Developer]

    DEV --> APPREPO[Application Repository]

    APPREPO -->|Web / Backend| JENKINS[Jenkins]
    JENKINS --> SONAR[SonarQube]
    JENKINS --> TRIVY[Trivy]
    JENKINS --> ECR[Amazon ECR]
    JENKINS --> GITOPS[GitOps Repository]

    GITOPS --> ARGO[Argo CD]
    ARGO --> EKS[Amazon EKS]

    APPREPO -->|Flutter| GHA[GitHub Actions]
    GHA --> GH_RUNNER[GitHub-hosted Runner]
    GH_RUNNER --> MOBILE_ARTIFACT[Signed APK / AAB]

    EKS --> ALB[Application Load Balancer]

    USERS[Users] -->|Web| ALB
    USERS -->|Mobile| MOBILE[Flutter App]
    MOBILE -->|API| ALB

🐞 Troubleshooting Practiced

Image Pull Problems

Typical causes:

Image missing

Wrong image tag

Wrong imagePullPolicy

kubectl describe pod <pod-name> -n physics

CrashLoopBackOff

kubectl logs <pod-name> -n physics
kubectl logs --previous <pod-name> -n physics
kubectl describe pod <pod-name> -n physics

PVC Permission Errors

Example:

EACCES: permission denied

Solution: use an Init Container to configure volume ownership for a non-root application container.

CreateContainerConfigError

Usually caused by a missing ConfigMap, Secret, or referenced key.

kubectl describe pod <pod-name> -n physics

Probe Failures

Example:

connection refused

Check application port, health path, logs, startup time, and probe configuration.

Kubernetes API Timeout

Example:

net/http: TLS handshake timeout

In local environments this can be caused by Minikube resource pressure or control-plane availability issues.

📈 Scalability

Stateless components can run multiple replicas:

Auth Service       ×2
Content Service    ×2
Progress Service   ×2
Gateway            ×2
Frontend           ×2

Production scaling options include:

Horizontal Pod Autoscaler

Karpenter / cluster autoscaling

External object storage for uploads

Redis-backed sessions

PostgreSQL HA or managed database migration

🛣️ DevOps Roadmap

Application                    ✅
Docker                         ✅
Docker Compose                 ✅
PostgreSQL                     ✅
Kubernetes                     ✅
Persistent Storage             ✅
ConfigMaps / Secrets           ✅
Health Probes                  ✅
Rolling Updates                ✅
Jenkins Pipeline               ✅
SonarQube                      ✅
Trivy                          ✅
GitOps / Argo CD               ✅
Flutter Client                 ✅
GitHub Actions for Flutter     ◉
Terraform Infrastructure       ◉
Ansible Configuration          ◉
Prometheus / Grafana           ⏳
Centralized Logging            ⏳
HTTPS / Domain                 ⏳
Object Storage for Uploads     ⏳
Production Hardening           ⏳

Legend:

✅ Implemented / practiced
◉ In active development
⏳ Planned

🧪 Useful Kubernetes Commands

kubectl get all -n physics
kubectl get pods -n physics
kubectl get svc -n physics
kubectl get ingress -n physics
kubectl get pvc -n physics
kubectl logs <pod-name> -n physics
kubectl logs -f <pod-name> -n physics
kubectl describe pod <pod-name> -n physics

🎯 Project Goals

The project demonstrates practical knowledge of:

Microservices architecture

Containerization

Kubernetes orchestration

Service discovery

Persistent storage

Stateful vs stateless workloads

Container security

Application configuration

Kubernetes troubleshooting

CI/CD

Static code analysis

Security scanning

Cloud container registries

GitOps deployment

Mobile CI/CD

Infrastructure as Code

Configuration management

Scaling and deployment strategies

🔗 Repositories

Application repository:

https://github.com/ahmedrabe33/physics-platform-app

GitOps repository:

https://github.com/ahmedrabe33/physics-platform-gitops

👨‍💻 Author

Ahmed Rabie
DevOps / Cloud Engineer

GitHub:

https://github.com/ahmedrabe33

⭐ Support

If you find this project useful, consider giving the repository a star ⭐.
