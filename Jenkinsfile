pipeline {
    agent any

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
                echo 'Build SentimentAI'
            }
        }

        stage('Test') {
            steps {
                echo 'Run tests'
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