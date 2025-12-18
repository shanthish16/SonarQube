pipeline {
  agent any

  tools {
    jdk 'jdk17'
    maven 'maven3'
  }

  environment {
    PROJECT_KEY = "my-java-app"
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
          withCredentials([string(credentialsId: 'token-sonar', variable: 'TOKEN_SONAR')]) {
            sh '''
              mvn -B sonar:sonar \
                -Dsonar.token=$TOKEN_SONAR \
                -Dsonar.projectKey=my-java-app \
                -Dsonar.projectName=my-java-app
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
