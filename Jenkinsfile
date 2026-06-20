pipeline {
    agent any

    stages {
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
