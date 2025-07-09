
# ReactJS E-Commerce Application - CI/CD Deployment Project

This project demonstrates my ability to build, deploy, and monitor a production-ready ReactJS application using a complete DevOps toolchain. It includes Dockerization, CI/CD with Jenkins, cloud deployment on AWS EC2, and real-time monitoring using open-source tools.

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Technology Stack](#technology-stack)
3. [Workflow Summary](#workflow-summary)
4. [Repository Structure](#repository-structure)
5. [CI/CD Pipeline with Jenkins](#cicd-pipeline-with-jenkins)
6. [Dockerization](#dockerization)
7. [AWS EC2 Deployment](#aws-ec2-deployment)
8. [Monitoring System](#monitoring-system)
9. [Screenshots Included](#screenshots-included)
10. [Project Outcome](#project-outcome)
11. [Contact](#contact)

---

## Project Overview

- Deploy a ReactJS application using CI/CD automation
- Use GitHub for version control, Jenkins for automation, Docker for containerization, and AWS EC2 for hosting
- Monitor uptime and health with Prometheus, Alertmanager, and Grafana

---

## Technology Stack

| Category       | Tools/Services                          |
|----------------|------------------------------------------|
| Frontend       | ReactJS                                  |
| Web Server     | NGINX                                     |
| Containerization | Docker, Docker Compose                |
| CI/CD          | Jenkins (Declarative Pipeline)           |
| Source Control | GitHub                                   |
| Image Registry | Docker Hub (Public: dev, Private: prod) |
| Cloud Hosting  | AWS EC2 (Ubuntu, t2.micro)               |
| Monitoring     | Prometheus, Alertmanager, Grafana        |

---

## Workflow Summary

1. Developer pushes code to `dev` branch on GitHub
2. GitHub webhook triggers Jenkins job
3. Jenkins builds Docker image and pushes to Docker Hub (`dev`)
4. Jenkins deploys container to EC2 Worker Node
5. When ready, `dev` is merged to `main`
6. Jenkins builds & pushes to `prod` Docker Hub (private)
7. Jenkins redeploys the updated container for production
8. Monitoring system tracks uptime & sends alerts if app fails

---

## Repository Structure

```
devops-build/
├── Dockerfile
├── docker-compose.yml
├── Jenkinsfile
├── build.sh
├── deploy.sh
├── .gitignore
├── .dockerignore
└── monitoring/
    ├── docker-compose.yml
    ├── prometheus/
    ├── grafana/
    ├── alertmanager/
    └── blackbox/
```

---

## CI/CD Pipeline with Jenkins

### Jenkins Configuration

- Pipeline type: Declarative Jenkinsfile from SCM
- Triggers: GitHub webhook on push events (both dev and main)
- Credentials used:
  - GitHub: `github-creds`
  - Docker Hub: `dockerhub-creds`
  - SSH to EC2 Agent: `worker-node-ssh`

### Pipeline Stages

1. **Checkout Code** – Fetches repo and determines active branch
2. **Build Image** – Tags and builds Docker image (based on branch)
3. **Push Image** – Authenticates and pushes to Docker Hub
4. **Deploy** – SSH into EC2, pull image, stop previous container, start new one
5. **Post Actions** – Docker cleanup and logout, workspace cleanup

---

## Dockerization

### Dockerfile

```dockerfile
FROM nginx:alpine
WORKDIR /usr/share/nginx/html
RUN rm -rf ./*
COPY build/ .
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

### docker-compose.yml

```yaml
version: '3'
services:
  react_app:
    build: .
    image: prasanth0003/react_app
    container_name: react_app
    ports:
      - "80:80"
    restart: unless-stopped
```

### Scripts

- `build.sh`: Builds Docker image with appropriate tag
- `deploy.sh`: Brings down old container and starts new one

---

## AWS EC2 Deployment

- Instance: `t2.micro`, Ubuntu
- Security Groups:
  - Port 80: Open to all
  - Port 22: Open only to my personal IP
- Docker & Docker Compose installed
- Access URL (example):  
  `http://13.51.56.138`

---

## Jenkinsfile (Declarative Pipeline)

The following `Jenkinsfile` was used to automate the CI/CD pipeline. It supports both `dev` and `main` branches dynamically.

```groovy
pipeline {
    agent any

    environment {
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-creds')
        SSH_CREDENTIALS = 'worker-node-ssh'
        DOCKER_REPO_DEV = 'prasanth0003/dev'
        DOCKER_REPO_PROD = 'prasanth0003/prod'
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: env.BRANCH_NAME, url: 'https://github.com/prasanth-wizard/devops-build.git'
                script {
                    COMMIT_HASH = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
                    IMAGE_TAG = "${env.BRANCH_NAME}-${BUILD_NUMBER}-${COMMIT_HASH}"
                    echo "Tag for Docker image: ${IMAGE_TAG}"
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    def imageName = env.BRANCH_NAME == 'main' ? DOCKER_REPO_PROD : DOCKER_REPO_DEV
                    sh "docker build -t ${imageName}:${IMAGE_TAG} -t ${imageName}:latest ."
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    def imageName = env.BRANCH_NAME == 'main' ? DOCKER_REPO_PROD : DOCKER_REPO_DEV
                    sh "echo ${DOCKERHUB_CREDENTIALS_PSW} | docker login -u ${DOCKERHUB_CREDENTIALS_USR} --password-stdin"
                    sh "docker push ${imageName}:${IMAGE_TAG}"
                    sh "docker push ${imageName}:latest"
                }
            }
        }

        stage('Deploy to EC2') {
            steps {
                script {
                    def imageName = env.BRANCH_NAME == 'main' ? DOCKER_REPO_PROD : DOCKER_REPO_DEV
                    sshagent([SSH_CREDENTIALS]) {
                        sh '''
                        ssh -o StrictHostKeyChecking=no ubuntu@<EC2-WORKER-IP> << EOF
                        docker pull ${imageName}:latest
                        docker stop react-app || true
                        docker rm react-app || true
                        docker run -d --name react-app -p 80:80 ${imageName}:latest
                        EOF
                        '''
                    }
                }
            }
        }
    }

    post {
        always {
            sh 'docker logout'
            cleanWs()
        }
    }
}
```

---

## Additional Files in Repository

These files support automation, builds, and container orchestration:

### build.sh

```bash
#!/bin/bash
docker build -t prasanth0003/react_app:dev .
```

### deploy.sh

```bash
#!/bin/bash
docker-compose down
docker-compose up -d
```

### .gitignore

```bash
node_modules/
.env
.DS_Store
build/
```

### .dockerignore

```bash
node_modules
.git
.gitignore
Dockerfile
README.md
```

---

## Monitoring System

All services deployed using Docker Compose in `monitoring/`.

### Tools Used:

- **Prometheus**: Scrapes metrics
- **Alertmanager**: Sends alerts (e.g. if app is down)
- **Grafana**: Dashboards for visualization
- **Blackbox Exporter**: HTTP checks

### Access:

- Prometheus: `http://<ip>:9090`
- Grafana: `http://<ip>:3000`

---


## Project Outcome

- Built and deployed a real-world ReactJS app via automated Jenkins pipelines
- Used secure credentials and webhook integration
- Showcased Docker image tagging and production separation
- Enabled continuous monitoring with real-time alerts

---

## Contact

- GitHub: [https://github.com/prasanth-wizard](https://github.com/prasanth-wizard)
- Docker Hub: [https://hub.docker.com/u/prasanth0003](https://hub.docker.com/u/prasanth0003)


