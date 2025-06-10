pipeline {
    agent any
    
    environment {
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-creds')
    }
    
    stages {
        stage('Build Dev Image') {
            when { branch 'dev' }
            steps {
                sh 'docker build -t prasanth0003/dev:latest .'
            }
        }
        
        stage('Push Dev Image') {
            when { branch 'dev' }
            steps {
                sh 'echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin'
                sh 'docker push prasanth0003/dev:latest'
            }
        }
        
        stage('Build Prod Image') {
            when { branch 'main' }
            steps {
                sh 'docker build -t prasanth0003/prod:latest .'
            }
        }
        
        stage('Push Prod Image') {
            when { branch 'main' }
            steps {
                sh 'echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin'
                sh 'docker push prasanth0003/prod:latest'
            }
        }
        
        stage('Deploy to Worker Node') {
            steps {
                sshagent(['worker-node-ssh']) {
                    sh 'ssh -o StrictHostKeyChecking=no ubuntu@13.51.56.138 "docker pull prasanth0003/dev:latest && docker-compose down && docker-compose up -d"'
                }
            }
        }
    }
    
    post {
        always {
            sh 'docker logout'
        }
    }
}
