pipeline {
    agent any

    environment {
        DOCKER_DEV_REPO  = "prasanth0003/dev"
        DOCKER_PROD_REPO = "prasanth0003/prod"
        // Add registry URL for clarity
        DOCKER_REGISTRY = "docker.io"
    }

    stages {
        stage('Checkout Code') {
            steps {
                checkout scm
                script {
                    // Get commit hash (7 characters is standard for Git)
                    env.COMMIT_HASH = sh(
                        script: 'git rev-parse --short=7 HEAD', 
                        returnStdout: true
                    ).trim()

                    // Normalize branch name
                    env.BRANCH_NAME = env.GIT_BRANCH?.replace("origin/", "") ?: sh(
                        script: "git rev-parse --abbrev-ref HEAD", 
                        returnStdout: true
                    ).trim()

                    // Validate branch and set tags
                    if (env.BRANCH_NAME == 'dev') {
                        env.IMAGE_NAME = "${DOCKER_REGISTRY}/${DOCKER_DEV_REPO}:${env.COMMIT_HASH}"
                        env.LATEST_TAG = "${DOCKER_REGISTRY}/${DOCKER_DEV_REPO}:latest"
                    } else if (env.BRANCH_NAME == 'main') {
                        env.IMAGE_NAME = "${DOCKER_REGISTRY}/${DOCKER_PROD_REPO}:${env.COMMIT_HASH}"
                        env.LATEST_TAG = "${DOCKER_REGISTRY}/${DOCKER_PROD_REPO}:latest"
                        
                        // Add semantic version tag for production (example using build number)
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
                    // Create build args including cache-from for optimization
                    def buildArgs = "-t ${env.IMAGE_NAME} -t ${env.LATEST_TAG}"
                    if (env.VERSION_TAG) {
                        buildArgs += " -t ${env.VERSION_TAG}"
                    }

                    sh """
                        docker build ${buildArgs} .
                        docker images | grep prasanth0003
                    """
                    
                    // Verify the image was built successfully
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
                        // Login with timeout and retry
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

                        // Push with retry logic
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
    }

    post {
        always {
            script {
                // Cleanup Docker credentials and workspace
                sh 'docker logout || true'
                
                // Optionally remove local images to save space
                if (env.IMAGE_NAME) {
                    sh "docker rmi ${env.IMAGE_NAME} || true"
                }
                
                cleanWs()
            }
        }
        success {
            echo "✅ Successfully built and pushed: ${env.IMAGE_NAME}"
            // Add notification (Slack, email, etc.)
        }
        failure {
            echo "❌ Pipeline failed for branch ${env.BRANCH_NAME}"
            // Add failure notification
        }
    }
}
