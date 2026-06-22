pipeline {
    agent any
    environment {
        REGISTRY = "ghcr.io"
        IMAGE_NAME = "neylie100/sentiment-ai"
        IMAGE_TAG = "${BUILD_NUMBER}"
    }
    stages {
        stage("Checkout") {
            steps {
                checkout scm
            }
        }
        stage("Install Dependencies") {
            steps {
                sh "pip install --user -r requirements.txt"
            }
        }
        stage("Unit Tests") {
            steps {
                sh "pytest"
            }
        }
        stage("Build Docker Image") {
            steps {
                sh "docker build -t ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG} ."
            }
        }
        stage("Docker Login") {
            steps {
                withCredentials([usernamePassword(credentialsId: "github-token", usernameVariable: "GH_USER", passwordVariable: "GH_TOKEN")]) {
                    sh "echo ${GH_TOKEN} | docker login ${REGISTRY} -u ${GH_USER} --password-stdin"
                }
            }
        }
        stage("Push Docker Image") {
            steps {
                sh "docker push ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
            }
        }
        stage("Terraform Init") {
            steps {
                dir("infra") {
                    sh "terraform init"
                }
            }
        }
        stage("Terraform Plan") {
            steps {
                dir("infra") {
                    sh "terraform plan -var=\"image_tag=${IMAGE_TAG}\" -out=tfplan"
                }
            }
        }
        stage("Terraform Apply") {
            steps {
                dir("infra") {
                    sh "terraform apply -auto-approve tfplan"
                }
            }
        }
        stage("Integration Test") {
            steps {
                sh "curl -f http://localhost:8001/health || exit 1"
            }
        }
    }
}
