pipeline {
    agent any

    environment {
        DEV_IMAGE = 'prasanth0003/dev:latest'
        PROD_IMAGE = 'prasanth0003/prod:latest'
        IMAGE_NAME = ''
    }

    stages {
        stage('Checkout SCM') {
            steps {
                git branch: "${env.BRANCH_NAME}",
                    credentialsId: 'github-creds',
                    url: 'https://github.com/prasanth-wizard/devops-build.git'
            }
        }

        stage('Set Image Name') {
            steps {
                script {
                    if (env.BRANCH_NAME == 'main' || env.BRANCH_NAME == 'master') {
                        IMAGE_NAME = "${PROD_IMAGE}"
                    } else {
                        IMAGE_NAME = "${DEV_IMAGE}"
                    }
                    echo "Docker Image to be built: ${IMAGE_NAME}"
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "Building Docker image for branch: ${env.BRANCH_NAME}"
                sh "docker build -t ${IMAGE_NAME} ."
            }
        }

        stage('Push Docker Image') {
            steps {
                echo 'Logging into Docker Hub and pushing the image'
                withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh '''
                        echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                        docker push ${IMAGE_NAME}
                    '''
                }
            }
        }

        stage('Deploy to Worker Node') {
            steps {
                sshagent(['worker-node-ssh']) {
                    sh '''
                        ssh -o StrictHostKeyChecking=no ubuntu@13.51.56.138 "
                            cd devops-build &&
                            docker pull ${IMAGE_NAME} &&
                            docker-compose down &&
                            docker-compose up -d
                        "
                    '''
                }
            }
        }
    }

    post {
        always {
            echo 'Cleaning up Docker credentials'
            sh 'docker logout || true'
        }
    }
}
