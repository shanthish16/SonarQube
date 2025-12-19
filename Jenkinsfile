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
        
        // Credentials for Nexus settings.xml injection
        NEXUS_USER  = credentials('nexus-user-id') 
        NEXUS_PASS  = credentials('nexus-pass-id')
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build & Package') {
            steps {
                // Using Managed Settings for Build
                configFileProvider([configFile(fileId: 'nexus-settings', variable: 'MAVEN_SETTINGS')]) {
                    sh 'mvn -B -s $MAVEN_SETTINGS clean package -DskipTests'
                }
            }
        }

        stage('Sonar Analysis') {
            steps {
                // Using Managed Settings for Sonar to ensure plugin dependencies resolve
                configFileProvider([configFile(fileId: 'nexus-settings', variable: 'MAVEN_SETTINGS')]) {
                    withSonarQubeEnv('SonarQube') {
                        withCredentials([string(credentialsId: 'sonarqube-token', variable: 'TOKEN_SONAR')]) {
                            sh """
                                mvn -B -s $MAVEN_SETTINGS sonar:sonar \
                                    -Dsonar.projectKey=${PROJECT_KEY} \
                                    -Dsonar.projectName=${PROJECT_KEY} \
                                    -Dsonar.token=$TOKEN_SONAR
                            """
                        }
                    }
                }
            }
        }

        stage('Quality Gate') {
            steps {
                // Increased timeout slightly for reliability
                timeout(time: 10, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Upload Artifact to Nexus') {
            steps {
                configFileProvider([configFile(fileId: 'nexus-settings', variable: 'MAVEN_SETTINGS')]) {
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
        success {
            echo "✅ BUILD & ANALYSIS SUCCESSFUL - Artifact uploaded to Nexus"
        }
        failure {
            echo "❌ PIPELINE FAILED"
        }
    }
}
