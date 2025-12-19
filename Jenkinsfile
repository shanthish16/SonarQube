pipeline {
  agent any

  tools {
    jdk 'jdk17'
    maven 'maven3'
  }

  environment {
    PROJECT_KEY = "enterprise-ci-java-service"
    NEXUS_URL   = "http://13.60.64.127:8081"
    NEXUS_REPO  = "maven-snapshots"
    
    // Updated based on your Credentials screenshot
    NEXUS_USER  = credentials('nexus-creds')
    NEXUS_PASS  = credentials('nexus-creds')
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Build & Package') {
      steps {
        // Changed ID to 'nexus settings' to match your Managed Files
        configFileProvider([configFile(fileId: 'nexus settings', variable: 'MAVEN_SETTINGS')]) {
          sh 'mvn -B -s $MAVEN_SETTINGS clean package -DskipTests'
        }
      }
    }

    stage('Sonar Analysis') {
      steps {
        configFileProvider([configFile(fileId: 'nexus settings', variable: 'MAVEN_SETTINGS')]) {
          withSonarQubeEnv('SonarQube') {
            // Matches 'sonarqube-token' ID
            withCredentials([string(credentialsId: 'sonarqube-token', variable: 'TOKEN_SONAR')]) {
              sh """
                mvn -B -s $MAVEN_SETTINGS sonar:sonar \
                  -Dsonar.projectKey=${PROJECT_KEY} \
                  -Dsonar.token=$TOKEN_SONAR
              """
            }
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

    stage('Upload Artifact to Nexus') {
      steps {
        configFileProvider([configFile(fileId: 'nexus settings', variable: 'MAVEN_SETTINGS')]) {
          sh """
            mvn -B deploy -DskipTests \
              -s $MAVEN_SETTINGS \
              -DaltDeploymentRepository=nexus::default::${NEXUS_URL}/repository/${NEXUS_REPO}
          """
        }
      }
    }
  }

  post {
    always {
      echo "Pipeline execution finished."
    }
  }
}
