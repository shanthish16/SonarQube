pipeline {
    agent any

    tools {
        jdk 'jdk17'
        maven 'maven3'
    }

    environment {
        PROJECT_KEY = "enterprise-ci-java-service"
        NEXUS_URL   = "http://16.170.157.215:30081"
        NEXUS_REPO  = "maven-snapshots"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build & Package') {
            steps {
                configFileProvider([configFile(fileId: 'nexus-settings', variable: 'MAVEN_SETTINGS')]) {
                    sh "mvn -B -s $MAVEN_SETTINGS clean package -DskipTests"
                }
            }
        }

        stage('Sonar Analysis') {
            steps {
                configFileProvider([configFile(fileId: 'nexus-settings', variable: 'MAVEN_SETTINGS')]) {
                    withSonarQubeEnv('SonarQube') {
                        withCredentials([string(credentialsId: 'sonarqube-token-K8s', variable: 'TOKEN_SONAR')]) {
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
                withCredentials([usernamePassword(credentialsId: 'nexus-creds-v3', usernameVariable: 'NEXUS_USER', passwordVariable: 'NEXUS_PASS')]) {
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

        // --- THIS STAGE IS NOW INSIDE THE 'STAGES' BLOCK ---
        stage('Build Docker Image') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'nexus-creds-v3', usernameVariable: 'USER', passwordVariable: 'PASS')]) {
                    script {
                        echo "Building lightweight Docker image using Multi-stage build..."
                        sh """
                            docker build \
                            --build-arg NEXUS_USER=${USER} \
                            --build-arg NEXUS_PASS=${PASS} \
                            --build-arg NEXUS_URL=${NEXUS_URL} \
                            -t ${PROJECT_KEY}:latest .
                        """
                    }
                }
            }
        }
    } // <-- Parent stages block ends here

    post {
        success {
            echo "✅ Build, Sonar, Nexus, and Docker Image build completed!"
        }
        failure {
            echo "❌ Pipeline failed. Check logs for details."
        }
    }
}
