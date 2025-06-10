pipeline {
    agent any

    environment {
        IMAGE_NAME = 'prasanth0003/dev:latest'
    }

    stages {
        stage('Checkout SCM') {
            steps {
                git branch: 'dev',
                    credentialsId: 'github-creds',
                    url: 'https://github.com/prasanth-wizard/devops-build.git'
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
                sshagent(['ubuntu']) {
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
            sh 'docker logout'
        }
    }
}

