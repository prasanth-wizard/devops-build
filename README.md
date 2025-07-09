
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
```

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
        DOCKER_DEV_REPO  = "prasanth0003/dev"
        DOCKER_PROD_REPO = "prasanth0003/prod"
        DOCKER_REGISTRY = "docker.io"
        AGENT_IP = "51.20.2.247"
        AGENT_SSH_CREDS = "agent-1-ssh-creds"
    }

    stages {
        stage('Checkout Code') {
            steps {
                checkout scm
                script {
                    env.COMMIT_HASH = sh(
                        script: 'git rev-parse --short=7 HEAD',
                        returnStdout: true
                    ).trim()

                    env.BRANCH_NAME = env.GIT_BRANCH?.replace("origin/", "") ?: sh(
                        script: "git rev-parse --abbrev-ref HEAD",
                        returnStdout: true
                    ).trim()

                    if (env.BRANCH_NAME == 'dev') {
                        env.BASE_IMAGE = "${DOCKER_REGISTRY}/${DOCKER_DEV_REPO}"
                    } else if (env.BRANCH_NAME == 'main') {
                        env.BASE_IMAGE = "${DOCKER_REGISTRY}/${DOCKER_PROD_REPO}"
                    } else {
                        error(" Unsupported branch '${env.BRANCH_NAME}'. Only 'dev' and 'main' are allowed.")
                    }

                    // Define tags as a string joined by spaces for docker build command
                    env.DOCKER_TAGS = "${env.BASE_IMAGE}:${env.COMMIT_HASH} ${env.BASE_IMAGE}:latest ${env.BASE_IMAGE}:${env.BRANCH_NAME} ${env.BASE_IMAGE}:${env.BUILD_NUMBER}"
                    
                    echo "Branch: ${env.BRANCH_NAME}"
                    echo " Image Tags: ${env.DOCKER_TAGS}"
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    // Convert tags string to build arguments
                    def buildArgs = env.DOCKER_TAGS.split().collect { "-t ${it}" }.join(' ')
                    
                    sh """
                        docker build ${buildArgs} .
                        docker images | grep prasanth0003
                    """

                    // Verify the image built successfully
                    def imageCheck = sh(
                        script: "docker inspect --type=image ${env.BASE_IMAGE}:${env.COMMIT_HASH}",
                        returnStatus: true
                    )
                    if (imageCheck != 0) {
                        error(" Docker image failed to build")
                    }
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-creds',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    script {
                        sh """
                            echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                        """

                        // Push each tag
                        env.DOCKER_TAGS.split().each { tag ->
                            retry(3) {
                                sh "docker push ${tag}"
                            }
                        }
                    }
                }
            }
        }

        stage('Deploy to Agent-1') {
            steps {
                script {
                    withCredentials([sshUserPrivateKey(
                        credentialsId: env.AGENT_SSH_CREDS,
                        usernameVariable: 'SSH_USER',
                        keyFileVariable: 'SSH_KEY'
                    )]) {
                        // Use the commit hash tag for deployment
                        def dockerImage = "${env.BASE_IMAGE}:${env.COMMIT_HASH}"

                        sh """
                            ssh -o StrictHostKeyChecking=no -i $SSH_KEY ${SSH_USER}@${env.AGENT_IP} "
                                docker pull ${dockerImage}
                                docker stop react-app || true
                                docker rm react-app || true
                                docker run -d --name react-app -p 80:80 ${dockerImage}
                            "
                        """
                        echo " Successfully deployed ${dockerImage} to ${env.AGENT_IP}"
                    }
                }
            }
        }
    }

    post {
        always {
            script {
                sh 'docker logout || true'
                // Clean up images safely
                try {
                    env.DOCKER_TAGS.split().each { tag ->
                        sh "docker rmi ${tag} || true"
                    }
                } catch (e) {
                    echo "Warning: Error during image cleanup - ${e.message}"
                }
                cleanWs()
            }
        }
        success {
            echo "Successfully built and pushed images with tags: ${env.DOCKER_TAGS}"
        }
        failure {
            echo "Pipeline failed for branch ${env.BRANCH_NAME}"
        }
    }
}
```

---

---

## Monitoring System

All monitoring services are deployed using Docker Compose located in the `monitoring/` directory.

### Folder Structure

```
monitoring/
├── alertmanager
│   └── alertmanager.yml
├── blackbox
│   └── blackbox.yml
├── docker-compose.yml
└── prometheus
    ├── alert_rules.yml
    └── prometheus.yml
```

---

### docker-compose.yml

```yaml
version: '3.8'

services:
  react-app:
    image: prasanth0003/dev:latest
    container_name: react-app
    ports:
      - "80:80"

  prometheus:
    image: prom/prometheus
    container_name: prometheus
    volumes:
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml
      - ./prometheus/alert_rules.yml:/etc/prometheus/alert_rules.yml
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
    ports:
      - "9090:9090"

  alertmanager:
    image: prom/alertmanager
    container_name: alertmanager
    volumes:
      - ./alertmanager/alertmanager.yml:/etc/alertmanager/alertmanager.yml
    command:
      - '--config.file=/etc/alertmanager/alertmanager.yml'
    ports:
      - "9093:9093"

  grafana:
    image: grafana/grafana
    container_name: grafana
    ports:
      - "3000:3000"
    depends_on:
      - prometheus

  node-exporter:
    image: prom/node-exporter
    container_name: node-exporter
    ports:
      - "9100:9100"
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    command:
      - '--path.procfs=/host/proc'
      - '--path.sysfs=/host/sys'
      - '--path.rootfs=/rootfs'

  blackbox:
    image: prom/blackbox-exporter
    container_name: blackbox
    ports:
      - "9115:9115"
    volumes:
      - ./blackbox:/config
    command:
      - '--config.file=/config/blackbox.yml'
```

---

### prometheus.yml

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

alerting:
  alertmanagers:
    - static_configs:
        - targets: ['alertmanager:9093']

rule_files:
  - alert_rules.yml

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node_exporter'
    static_configs:
      - targets: ['node-exporter:9100']

  - job_name: 'react_http_probe'
    metrics_path: /probe
    params:
      module: [http_2xx]
    static_configs:
      - targets:
        - http://51.20.2.247
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: blackbox:9115
```

---

### alert_rules.yml

```yaml
groups:
  - name: react_app_alerts
    rules:
      - alert: ReactAppContainerDown
        expr: up{job="react_app"} == 0
        for: 15s
        labels:
          severity: critical
        annotations:
          summary: "React container unreachable"
          description: "Prometheus can't connect to react-app on port 80."

      - alert: ReactHTTPProbeFailed
        expr: probe_success{job="react_http_probe"} == 0
        for: 15s
        labels:
          severity: critical
        annotations:
          summary: "React HTTP health check failed"
          description: "React app did not return HTTP 200."
```

---

### alertmanager.yml


```yaml
global:
  smtp_smarthost: 'smtp.gmail.com:587'
  smtp_from: 'prasanthkalichamy30@gmail.com'
  smtp_auth_username: 'prasanthkalichamy30@gmail.com'
  smtp_auth_password: 'aqsa nfqv kkhz rloa'
  smtp_require_tls: true

route:
  receiver: 'email-alert'

receivers:
  - name: 'email-alert'
    email_configs:
      - to: 'prasanthkalichamy30@gmail.com'
        send_resolved: true
```

---

### blackbox.yml

```yaml
modules:
  http_2xx:
    prober: http
    timeout: 5s
    http:
      valid_http_versions: ["HTTP/1.1", "HTTP/2"]
      valid_status_codes: [200]
      method: GET
```

---

### Run Monitoring Stack

```bash
cd monitoring/
docker-compose up -d
```

Access monitoring dashboards:

- Prometheus: http://localhost:9090
- Grafana: http://localhost:3000
- Alertmanager: http://localhost:9093
- Blackbox Exporter: http://localhost:9115



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


