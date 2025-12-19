pipeline {
    agent any

    tools {
        jdk 'jdk17'
        maven 'maven3'
    }

    environment {
        PROJECT_KEY = "enterprise-ci-java-service"
        NEXUS_URL   = "http://13.60.195.8:8081"
        NEXUS_REPO  = "maven-snapshots"
        
        // --- DEPLOYMENT VARIABLES ---
        TARGET_EC2_IP = "51.20.135.39" 
        SSH_CRED_ID   = "ec2-ssh-key" 
        APP_DIR       = "/var/www/myapp"
        
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
                configFileProvider([configFile(fileId: 'nexus-settings', variable: 'MAVEN_SETTINGS')]) {
                    sh 'mvn -B -s $MAVEN_SETTINGS clean package -DskipTests'
                }
            }
        }

        stage('Sonar Analysis') {
            steps {
                configFileProvider([configFile(fileId: 'nexus-settings', variable: 'MAVEN_SETTINGS')]) {
                    withSonarQubeEnv('SonarQube') {
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
                configFileProvider([configFile(fileId: 'nexus-settings', variable: 'MAVEN_SETTINGS')]) {
                    sh """
                        mvn -B deploy -DskipTests \
                          -s $MAVEN_SETTINGS \
                          -DaltDeploymentRepository=nexus::default::${NEXUS_URL}/repository/${NEXUS_REPO}
                    """
                }
            }
        }

        stage('Deploy to Ubuntu EC2') {
            steps {
                sshagent([env.SSH_CRED_ID]) {
                    sh """
                        # 1. Clean and Copy
                        ssh -o StrictHostKeyChecking=no ubuntu@${TARGET_EC2_IP} "rm -rf ${APP_DIR}/*.jar"
                        scp -o StrictHostKeyChecking=no target/enterprise-ci-java-service-1.0-SNAPSHOT.jar ubuntu@${TARGET_EC2_IP}:${APP_DIR}/app.jar

                        # 2. Start Application
                        # We use /usr/bin/java and wrap in ( ) & to fully detach the process
                        # The 'sleep' gives the process a second to write the log file before SSH closes
                        ssh -o StrictHostKeyChecking=no ubuntu@${TARGET_EC2_IP} "
                            pkill -f app.jar || true
                            cd ${APP_DIR}
                            (nohup /usr/bin/java -jar app.jar > app.log 2>&1 &)
                            sleep 2
                        "
                        
                        echo "Deployment command completed successfully."
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
