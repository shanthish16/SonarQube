pipeline {
  agent any

  tools {
    jdk 'jdk17'
    maven 'maven3'
  }

  environment {
    PROJECT_KEY = "enterprise-ci-java-service"
    GROUP_ID    = "com.example"
    ARTIFACT_ID = "enterprise-ci-java-service"
    VERSION     = "1.0-SNAPSHOT"

    NEXUS_URL   = "http://13.60.64.127:8081"
    NEXUS_REPO  = "maven-snapshots"

    DEPLOY_DIR  = "/opt/app"
  }

  stages {

    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Build & Package') {
      steps {
        sh 'mvn clean package -DskipTests'
      }
    }

    stage('Sonar Analysis') {
      steps {
        withSonarQubeEnv('SonarQube') {
          withCredentials([string(credentialsId: 'sonarqube-token', variable: 'TOKEN_SONAR')]) {
            sh '''
              mvn sonar:sonar \
                -Dsonar.projectKey=${PROJECT_KEY} \
                -Dsonar.projectName=${PROJECT_KEY} \
                -Dsonar.token=$TOKEN_SONAR
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

    stage('Upload Artifact to Nexus') {
      steps {
        configFileProvider([configFile(
          fileId: 'nexus-settings',
          variable: 'MAVEN_SETTINGS'
        )]) {
          sh '''
            mvn deploy -DskipTests \
              -s $MAVEN_SETTINGS \
              -DaltDeploymentRepository=nexus::default:: http://13.60.64.127:8081/repository/maven-snapshots
          '''
        }
      }
    }

    stage('Pull Artifact from Nexus') {
      steps {
        sh '''
          mvn dependency:get \
            -DrepoUrl=${NEXUS_URL}/repository/${NEXUS_REPO} \
            -DgroupId=${GROUP_ID} \
            -DartifactId=${ARTIFACT_ID} \
            -Dversion=${VERSION} \
            -Dpackaging=jar \
            -Ddest=target/app.jar
        '''
      }
    }

    stage('Deploy on EC2 (Local)') {
      steps {
        sh '''
          sudo mkdir -p ${DEPLOY_DIR}
          sudo cp target/app.jar ${DEPLOY_DIR}/app.jar
          sudo pkill -f app.jar || true
          sudo nohup java -jar ${DEPLOY_DIR}/app.jar > ${DEPLOY_DIR}/app.log 2>&1 &
        '''
      }
    }
  }

  post {
    success {
      echo "✅ FULL PIPELINE SUCCESSFUL"
    }
    failure {
      echo "❌ PIPELINE FAILED"
    }
  }
}
