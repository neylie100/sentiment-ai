pipeline {
    agent any

    environment {
        IMAGE_NAME = "sentiment-ai"
        IMAGE_TAG = "latest"
        REGISTRY = "ghcr.io/TON_USER"
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
                // On lance les tests simplement sans variables complexes qui bloquent la Sandbox
                sh "docker run --name test-runner ${IMAGE_NAME}:${IMAGE_TAG} pytest tests/ -v"
            }
            post {
                always {
                    sh "docker rm -f test-runner || true"
                }
            }
        }

        stage("SonarQube Analysis") {
            environment {
                SONARQUBE_TOKEN = credentials("sonar-token")
            }
            steps {
                withSonarQubeEnv("sonarqube") {
                    sh """
                    docker run --rm \
                      --network cicd-network \
                      --volumes-from jenkins \
                      -w "$WORKSPACE" \
                      -e SONAR_HOST_URL="$SONAR_HOST_URL" \
                      -e SONAR_TOKEN="$SONARQUBE_TOKEN" \
                      sonarsource/sonar-scanner-cli:latest \
                      sonar-scanner \
                      -Dsonar.projectKey=sentiment-ai \
                      -Dsonar.projectName=SentimentAI \
                      -Dsonar.projectBaseDir="$WORKSPACE" \
                      -Dsonar.sources=src \
                      -Dsonar.python.version=3.11 \
                      -Dsonar.sourceEncoding=UTF-8
                    """
                }
            }
        }

        stage("Quality Gate") {
            steps {
                timeout(time: 5, unit: "MINUTES") {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage("Security Scan") {
            steps {
                // Version simplifiée et robuste du scan Trivy
                sh "docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:latest image --severity HIGH,CRITICAL --format table ${IMAGE_NAME}:${IMAGE_TAG}"
            }
        }

        stage("Push") {
            when { branch "main" }
            steps {
                withCredentials([usernamePassword(
                    credentialsId: "github-token",
                    usernameVariable: "REGISTRY_USER",
                    passwordVariable: "REGISTRY_PASS")
                ]) {
                    sh """
                    echo ${REGISTRY_PASS} | docker login ghcr.io -u ${REGISTRY_USER} --password-stdin
                    docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}
                    docker push ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}
                    """
                }
            }
        }

        stage("Deploy Staging") {
            when { branch "main" }
            steps {
                sh "docker compose -f docker-compose.yml -p staging down || true"
                sh "docker compose -f docker-compose.yml -p staging up -d"
                echo "Staging disponible sur http://localhost:8001"
            }
        }
    }
}