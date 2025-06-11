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

                    // Base image name without tag
                    if (env.BRANCH_NAME == 'dev') {
                        env.BASE_IMAGE_NAME = "${DOCKER_REGISTRY}/${DOCKER_DEV_REPO}"
                    } else if (env.BRANCH_NAME == 'main') {
                        env.BASE_IMAGE_NAME = "${DOCKER_REGISTRY}/${DOCKER_PROD_REPO}"
                    } else {
                        error("🚫 Unsupported branch '${env.BRANCH_NAME}'. Only 'dev' and 'main' are allowed.")
                    }

                    // Allow any tag format - these are just suggestions
                    env.IMAGE_TAGS = """
                        ${env.BASE_IMAGE_NAME}:${env.COMMIT_HASH}
                        ${env.BASE_IMAGE_NAME}:latest
                        ${env.BASE_IMAGE_NAME}:${env.BRANCH_NAME}
                        ${env.BASE_IMAGE_NAME}:${env.BUILD_NUMBER}
                        ${env.BASE_IMAGE_NAME}:${env.BRANCH_NAME}-${env.BUILD_NUMBER}
                    """.trim().split('\n').collect { it.trim() }.findAll { it }

                    echo "🔍 Branch: ${env.BRANCH_NAME}"
                    echo "🐳 Available Image Tags: ${env.IMAGE_TAGS.join(', ')}"
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    // Build with all tags
                    def buildArgs = env.IMAGE_TAGS.collect { "-t ${it}" }.join(' ')
                    
                    sh """
                        docker build ${buildArgs} .
                        docker images | grep prasanth0003
                    """

                    // Verify at least one image built successfully
                    def imageCheck = sh(
                        script: "docker inspect --type=image ${env.IMAGE_TAGS[0]}",
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
                        // Login to Docker Hub
                        sh """
                            echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                        """

                        // Push all tags with retry logic
                        env.IMAGE_TAGS.each { tag ->
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
                        // Deploy using the first tag (could be changed to any preferred tag)
                        def dockerImage = env.IMAGE_TAGS[0]

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
                // Clean up all built images
                env.IMAGE_TAGS.each { tag ->
                    sh "docker rmi ${tag} || true"
                }
                cleanWs()
            }
        }
        success {
            echo "Successfully built and pushed images with tags: ${env.IMAGE_TAGS.join(', ')}"
        }
        failure {
            echo "Pipeline failed for branch ${env.BRANCH_NAME}"
        }
    }
}
