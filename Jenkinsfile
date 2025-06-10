pipeline {
    agent any

    environment {
        DOCKER_DEV_REPO  = "prasanth0003/dev"
        DOCKER_PROD_REPO = "prasanth0003/prod"
<<<<<<< HEAD
        COMMIT_HASH      = ''
=======
>>>>>>> dev
    }

    stages {
        stage('Checkout Code') {
            steps {
                checkout scm
                script {
                    // ✅ Get commit hash
<<<<<<< HEAD
                    env.COMMIT_HASH = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()

                    // ✅ Get branch name (remove origin/ if exists)
                    env.BRANCH_NAME = (env.GIT_BRANCH ?: sh(script: "git rev-parse --abbrev-ref HEAD", returnStdout: true).trim()).replace('origin/', '')

                    // ✅ Set Docker image tags based on branch
                    if (env.BRANCH_NAME == 'dev') {
                        env.IMAGE_NAME = "${DOCKER_DEV_REPO}:${COMMIT_HASH}"
                        env.LATEST_TAG = "${DOCKER_DEV_REPO}:latest"
                    } else if (env.BRANCH_NAME == 'main') {
                        env.IMAGE_NAME = "${DOCKER_PROD_REPO}:${COMMIT_HASH}"
                        env.LATEST_TAG = "${DOCKER_PROD_REPO}:latest"
                    } else {
                        error("🚫 Unsupported branch: ${env.BRANCH_NAME}. Use 'main' or 'dev' only.")
                    }

                    echo "🔍 Branch: ${env.BRANCH_NAME}"
                    echo "🐳 Docker Image: ${env.IMAGE_NAME}, ${env.LATEST_TAG}"
=======
                    def hash = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
                    env.COMMIT_HASH = hash

                    // ✅ Get branch name
                    def branch = (env.GIT_BRANCH ?: sh(script: "git rev-parse --abbrev-ref HEAD", returnStdout: true)).trim().replace("origin/", "")
                    env.BRANCH_NAME = branch

                    // ✅ Set image names
                    if (branch == 'dev') {
                        env.IMAGE_NAME = "${DOCKER_DEV_REPO}:${env.COMMIT_HASH}"
                        env.LATEST_TAG = "${DOCKER_DEV_REPO}:latest"
                    } else if (branch == 'main') {
                        env.IMAGE_NAME = "${DOCKER_PROD_REPO}:${env.COMMIT_HASH}"
                        env.LATEST_TAG = "${DOCKER_PROD_REPO}:latest"
                    } else {
                        error("🚫 Unsupported branch '${branch}'. Only 'dev' and 'main' are allowed.")
                    }

                    echo "🔍 Branch: ${env.BRANCH_NAME}"
                    echo "🐳 Image: ${env.IMAGE_NAME}, ${env.LATEST_TAG}"
>>>>>>> dev
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh """
                    docker build -t ${env.IMAGE_NAME} -t ${env.LATEST_TAG} .
                    docker images | grep prasanth0003
                """
            }
        }

        stage('Push Docker Image to Docker Hub') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-creds',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh """
                        echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                        docker push ${env.IMAGE_NAME}
                        docker push ${env.LATEST_TAG}
                    """
                }
            }
        }
    }

    post {
        always {
            sh 'docker logout || true'
            cleanWs()
        }
        success {
            echo "✅ Docker image pushed successfully for branch ${env.BRANCH_NAME}"
        }
        failure {
            echo "❌ Pipeline failed for branch ${env.BRANCH_NAME}"
        }
    }
}
