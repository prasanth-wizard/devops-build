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
                        error("🚫 Unsupported branch '${env.BRANCH_NAME}'. Only 'dev' and 'main' are allowed.")
                    }

                    // Define tags as a string joined by spaces for docker build command
                    env.DOCKER_TAGS = "${env.BASE_IMAGE}:${env.COMMIT_HASH} ${env.BASE_IMAGE}:latest ${env.BASE_IMAGE}:${env.BRANCH_NAME} ${env.BASE_IMAGE}:${env.BUILD_NUMBER}"
                    
                    echo "🔍 Branch: ${env.BRANCH_NAME}"
                    echo "🐳 Image Tags: ${env.DOCKER_TAGS}"
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
                        error("❌ Docker image failed to build")
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
                        echo "🚀 Successfully deployed ${dockerImage} to ${env.AGENT_IP}"
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
