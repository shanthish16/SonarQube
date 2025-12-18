pipeline {
  agent any

  tools {
    jdk 'jdk17'
    maven 'maven3'
  }

  environment {
    PROJECT_KEY = "enterprise-ci-java-service"
  }

  stages {

    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Build') {
      steps {
        sh 'mvn -B clean compile'
      }
    }

    stage('Sonar Analysis') {
      steps {
        withSonarQubeEnv('SonarQube') {
          withCredentials([string(credentialsId: 'sonarqube-token', variable: 'sonarqube-token')]) {
            sh '''
              mvn -B sonar:sonar \
                -Dsonar.token=$sonarqube-token \
                -Dsonar.projectKey=enterprise-ci-java-service \
                -Dsonar.projectName=enterprise-ci-java-service
            '''
          }
        }
      }
    }

    stage('Quality Gate') {
      steps {
        timeout(time: 10, unit: 'MINUTES') {
          waitForQualityGate abortPipeline: true
        }
      }
    }
  }

  post {
    success {
      echo "✅ Sonar Analysis completed and Quality Gate PASSED"
    }
    failure {
      echo "❌ Pipeline failed (Sonar or Quality Gate issue)"
    }
  }
}
