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

        stage('Build & Test') {
            steps {
                sh '''
                # 1. Build de l'image Docker
                docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .

                # 2. Supprimer un éventuel conteneur test-runner résiduel
                docker rm -f test-runner 2>/dev/null || true

                # 3. Lancer les tests dans un conteneur nommé 'test-runner'
                set +e
                docker run \
                  -e CI=true \
                  --name test-runner \
                  ${IMAGE_NAME}:${IMAGE_TAG} \
                  pytest tests/ -v \
                  --cov=src \
                  --cov-report=xml:/tmp/coverage.xml \
                  --cov-report=term-missing \
                  --cov-fail-under=70
                
                # Récupération sécurisée du code de sortie des tests
                TEST_EXIT_CODE=\$?
                set -e

                # 4. Copier coverage.xml depuis le conteneur vers le workspace Jenkins
                docker cp test-runner:/tmp/coverage.xml ./coverage.xml 2>/dev/null || true

                # 5. Nettoyer le conteneur de test
                docker rm -f test-runner 2>/dev/null || true

                # 6. Retourner le code de sortie des tests
                exit \$TEST_EXIT_CODE
                '''
            }
            post {
                failure { 
                    echo 'Tests échoués ou couverture de code insuffisante (< 70%)' 
                }
            }
        }

        stage('SonarQube Analysis') {
            environment {
                SONARQUBE_TOKEN = credentials('sonar-token')
            }
            steps {
                withSonarQubeEnv('sonarqube') {
                    sh '''
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
                      -Dsonar.python.coverage.reportPaths=coverage.xml \
                      -Dsonar.sourceEncoding=UTF-8 \
                      -Dsonar.scanner.metadataFilePath=$WORKSPACE/report-task.txt
                    '''
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 15, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Security Scan') {
            steps {
                sh """
                docker run --rm \
                  -v /var/run/docker.sock:/var/run/docker.sock \
                  -v trivy-cache:/root/.cache/trivy \
                  aquasec/trivy:latest image \
                  --severity HIGH,CRITICAL \
                  --exit-code 1 \
                  --format table \
                  ${IMAGE_NAME}:${IMAGE_TAG}
                """
            }
            post {
                failure {
                    echo 'Vulnérabilités CRITICAL ou HIGH détectées !'
                    echo 'Corrigez les dépendances avant de déployer.'
                }
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