pipeline {
    agent any

    environment {
        IMAGE_NAME = "sentiment-ai"
        IMAGE_TAG = "latest"
    }

    stages {
        stage("Checkout") {
            steps {
                checkout scm
            }
        }

        stage("Build And Test") {
            steps {
                sh "docker build -t ${IMAGE_NAME}:${IMAGE_TAG} ."
                sh "docker rm -f test-runner || true"
                sh "docker run --name test-runner ${IMAGE_NAME}:${IMAGE_TAG} pytest tests/ -v"
            }
            post {
                always {
                    sh "docker rm -f test-runner || true"
                }
            }
        }

        stage("Security Scan") {
            steps {
                echo "Lancement du scan de s?curit? Trivy..."
                sh "docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:latest image --severity HIGH,CRITICAL --format table ${IMAGE_NAME}:${IMAGE_TAG}"
            }
        }
    }
}
