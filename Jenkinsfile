pipeline {
    agent any

    options {
        disableConcurrentBuilds()  // Prevent parallel builds of the same branch
    }

    environment {
        // Docker Hub image names
        DEV_IMAGE  = 'prasanth0003/dev:latest'
        PROD_IMAGE = 'prasanth0003/prod:latest'
        // Get commit short hash for unique tagging
        COMMIT_HASH = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
    }

    stages {
        stage('Checkout & Branch Detection') {
            steps {
                checkout scm
                script {
                    // Get current branch name reliably
                    env.BRANCH_NAME = env.GIT_BRANCH ?: sh(script: "git rev-parse --abbrev-ref HEAD", returnStdout: true).trim()
                    
                    // Set Docker image based on branch
                    if (env.BRANCH_NAME == 'main') {
                        env.IMAGE_NAME = "${PROD_IMAGE}"
                        env.ALT_TAG    = "prasanth0003/prod:${COMMIT_HASH}"
                    } else {
                        env.IMAGE_NAME = "${DEV_IMAGE}"
                        env.ALT_TAG    = "prasanth0003/dev:${COMMIT_HASH}-${env.BRANCH_NAME.replace('/', '-')}"
                    }
                    
                    echo "Building for BRANCH: ${env.BRANCH_NAME}"
                    echo "Using IMAGE: ${env.IMAGE_NAME}"
                    echo "Additional TAG: ${env.ALT_TAG}"
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh """
                    docker build -t ${env.IMAGE_NAME} -t ${env.ALT_TAG} .
                    docker images | grep prasanth0003
                """
            }
        }

        stage('Push to Docker Hub') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-creds',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh """
                        echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                        docker push ${env.IMAGE_NAME}
                        docker push ${env.ALT_TAG}
                    """
                }
            }
        }

        stage('Deploy to Worker Node') {
            when {
                // Only deploy if branch is 'main' or 'dev'
                anyOf {
                    branch 'main'
                    branch 'dev'
                }
            }
            steps {
                sshagent(['worker-node-ssh']) {
                    sh """
                        ssh -o StrictHostKeyChecking=no ubuntu@13.51.56.138 "
                            cd devops-build &&
                            docker pull ${env.IMAGE_NAME} &&
                            docker-compose down &&
                            docker-compose up -d
                        "
                    """
                }
            }
        }
    }

    post {
        always {
            sh 'docker logout || true'
            cleanWs()  // Clean workspace after build
        }
        success {
            echo "Pipeline succeeded for ${env.BRANCH_NAME}"
        }
        failure {
            echo "Pipeline failed for ${env.BRANCH_NAME}"
            // Add email/slack notification here if needed
        }
    }
}
