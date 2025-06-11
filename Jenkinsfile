pipeline {
    agent any

    environment {
        DOCKER_DEV_REPO  = "prasanth0003/dev"
        DOCKER_PROD_REPO = "prasanth0003/prod"
        DOCKER_REGISTRY = "docker.io"
        // Add agent IP for deployment
        AGENT_IP = "51.20.2.247"
        AGENT_SSH_CREDS = "agent-1-ssh-creds" // Jenkins SSH credentials ID for agent-1
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
                        env.IMAGE_NAME = "${DOCKER_REGISTRY}/${DOCKER_DEV_REPO}:${env.COMMIT_HASH}"
                        env.LATEST_TAG = "${DOCKER_REGISTRY}/${DOCKER_DEV_REPO}:latest"
                    } else if (env.BRANCH_NAME == 'main') {
                        env.IMAGE_NAME = "${DOCKER_REGISTRY}/${DOCKER_PROD_REPO}:${env.COMMIT_HASH}"
                        env.LATEST_TAG = "${DOCKER_REGISTRY}/${DOCKER_PROD_REPO}:latest"
<<<<<<< HEAD
                        // Add semantic version tag for production
=======
>>>>>>> dev
                        env.VERSION_TAG = "${DOCKER_REGISTRY}/${DOCKER_PROD_REPO}:1.0.${env.BUILD_NUMBER}"
                    } else {
                        error("🚫 Unsupported branch '${env.BRANCH_NAME}'. Only 'dev' and 'main' are allowed.")
                    }

                    echo "🔍 Branch: ${env.BRANCH_NAME}"
                    echo "🐳 Image Tags: ${env.IMAGE_NAME}, ${env.LATEST_TAG}" +
                         (env.VERSION_TAG ? ", ${env.VERSION_TAG}" : "")
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    def buildArgs = "-t ${env.IMAGE_NAME} -t ${env.LATEST_TAG}"
                    if (env.VERSION_TAG) {
                        buildArgs += " -t ${env.VERSION_TAG}"
                    }

                    sh """
                        docker build ${buildArgs} .
                        docker images | grep prasanth0003
                    """

<<<<<<< HEAD
                    // Verify the image was built successfully
=======
>>>>>>> dev
                    def imageCheck = sh(
                        script: "docker inspect --type=image ${env.IMAGE_NAME}",
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
                        def loginAttempts = 0
                        def maxAttempts = 3
                        def loggedIn = false

                        while (loginAttempts < maxAttempts && !loggedIn) {
                            try {
                                sh """
                                    echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                                """
                                loggedIn = true
                            } catch (e) {
                                loginAttempts++
                                if (loginAttempts >= maxAttempts) {
                                    error("❌ Failed to login to Docker Hub after ${maxAttempts} attempts")
                                }
                                sleep(time: 5, unit: 'SECONDS')
                            }
                        }

                        def pushTags = [env.IMAGE_NAME, env.LATEST_TAG]
                        if (env.VERSION_TAG) {
                            pushTags << env.VERSION_TAG
                        }

                        pushTags.each { tag ->
                            retry(3) {
                                sh "docker push ${tag}"
                            }
                        }
                    }
                }
            }
        }

        // ===== NEW DEPLOYMENT STAGE =====
        stage('Deploy to Agent-1') {
            when {
                // Only deploy if branch is 'dev' (modify as needed)
                branch 'dev'
            }
            steps {
                script {
                    // Use SSH to deploy the container on agent-1
                    withCredentials([sshUserPrivateKey(
                        credentialsId: env.AGENT_SSH_CREDS,
                        usernameVariable: 'SSH_USER',
                        keyFileVariable: 'SSH_KEY'
                    )]) {
                        def dockerImage = env.LATEST_TAG // or env.IMAGE_NAME
                        
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
<<<<<<< HEAD

                // Optionally remove local images to save space
                if (env.IMAGE_NAME) {
                    sh "docker rmi ${env.IMAGE_NAME} || true"
                }

=======
                if (env.IMAGE_NAME) {
                    sh "docker rmi ${env.IMAGE_NAME} || true"
                }
>>>>>>> dev
                cleanWs()
            }
        }
        success {
            echo "✅ Successfully built and pushed: ${env.IMAGE_NAME}"
        }
        failure {
            echo "❌ Pipeline failed for branch ${env.BRANCH_NAME}"
        }
    }
}
