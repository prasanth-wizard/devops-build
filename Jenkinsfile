pipeline {
    agent any

    environment {
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-creds') // Docker Hub credentials
        IMAGE_TAG = "${env.BRANCH_NAME == 'main' ? 'prod' : 'dev'}"
    }

    stages {

        stage('Build Docker Image') {
            steps {
                echo "Building Docker image for branch: ${env.BRANCH_NAME}"
                sh 'docker build -t prasanth0003/$IMAGE_TAG:latest .'
            }
        }

        stage('Push Docker Image') {
            steps {
                echo "Logging into Docker Hub and pushing the image"
                sh 'echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin'
                sh 'docker push prasanth0003/$IMAGE_TAG:latest'
            }
        }

        stage('Deploy to Worker Node') {
            steps {
                sshagent(['worker-node-ssh']) {
                    sh """
                        ssh -o StrictHostKeyChecking=no ubuntu@13.51.56.138 '
                            docker pull prasanth0003/$IMAGE_TAG:latest &&
                            docker-compose down &&
                            docker-compose up -d
                        '
                    """
                }
            }
        }
    }

    post {
        always {
            echo "Cleaning up Docker credentials"
            sh 'docker logout'
        }
    }
}
