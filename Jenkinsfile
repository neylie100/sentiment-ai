pipeline {
    agent any
    environment {
        IMAGE_NAME = "sentiment-ai"
        IMAGE_TAG = "latest"
    }
    stages {
        stage('Checkout SCM') { steps { checkout scm } }
        stage('Checkout') { steps { checkout scm } }
        stage('Build And Test') {
            steps {
                sh "docker build -t ${IMAGE_NAME}:${IMAGE_TAG} ."
                sh "docker rm -f test-runner || true"
                sh "docker run --name test-runner ${IMAGE_NAME}:${IMAGE_TAG} pytest tests/ -v"
            }
            post { always { sh "docker rm -f test-runner || true" } }
        }
        stage('SonarQube Analysis') {
            steps {
                // Remplacez 'sonarqube' par le nom exact configur? dans Jenkins
                withSonarQubeEnv('sonarqube') {
                    echo "Analyse SonarQube..."
                }
            }
        }
        stage('Quality Gate') {
            steps {
                echo "V?rification du Quality Gate..."
            }
        }
        stage('Security Scan') {
            steps {
                sh "docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:latest image --severity HIGH,CRITICAL --format table ${IMAGE_NAME}:${IMAGE_TAG}"
            }
        }
        stage('Push') { steps { echo "Push de l'image..." } }
        stage('Deploy Staging') { steps { echo "D?ploiement en Staging..." } }
    }
}
