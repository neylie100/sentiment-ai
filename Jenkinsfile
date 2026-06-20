pipeline {
    agent any

    environment {
        IMAGE_NAME = "mon-image"
        IMAGE_TAG = "latest"
        REGISTRY = "ghcr.io/TON_USER"
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
                echo "Branche : ${env.BRANCH_NAME}"
                echo "Commit : ${env.GIT_COMMIT}"
                sh 'git log --oneline -5'
            }
        }

        stage('Build') {
            steps {
                sh "docker build -t ${IMAGE_NAME}:${IMAGE_TAG} ."
            }
        }

        stage('Test') {
            steps {
                sh """
                docker run --rm \
                    ${IMAGE_NAME}:${IMAGE_TAG} \
                    pytest tests/ -v \
                    --cov=src \
                    --cov-report=xml:coverage.xml \
                    --cov-report=term-missing \
                    --cov-fail-under=70
                """
            }
        }

        stage('Build & Test Log') {
            steps {
                echo 'Build et tests terminés'
            }
        }

        stage('Push') {
            when {
                branch 'main'
            }

            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'github-token',
                    usernameVariable: 'REGISTRY_USER',
                    passwordVariable: 'REGISTRY_PASS'
                )]) {

                    sh """
                    echo ${REGISTRY_PASS} | docker login ghcr.io \
                        -u ${REGISTRY_USER} --password-stdin

                    docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}
                    docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${REGISTRY}/${IMAGE_NAME}:latest

                    docker push ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}
                    docker push ${REGISTRY}/${IMAGE_NAME}:latest
                    """
                }
            }
        }
    }

    post {
        success {
            echo 'Pipeline réussi'
        }

        failure {
            echo 'Pipeline échoué'
        }
    }
}