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
        
        // --- NEW DEPLOYMENT VARIABLES ---
        TARGET_EC2_IP = "YOUR_TARGET_EC2_PUBLIC_IP" // <--- Change this to your Target EC2 IP
        SSH_CRED_ID   = "ec2-ssh-key"                // <--- Must match the ID in Jenkins Credentials
        APP_DIR       = "/var/www/myapp"
        // --------------------------------
        
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
                // Ensure 'ssh-agent' plugin is installed in Jenkins
                sshagent([env.SSH_CRED_ID]) {
                    sh """
                        # 1. Remove old jar files on target
                        ssh -o StrictHostKeyChecking=no ubuntu@${TARGET_EC2_IP} "rm -rf ${APP_DIR}/*.jar"

                        # 2. Copy the newly built jar from the 'target' folder to EC2
                        # Adjust 'target/*.jar' if your jar name is specific
                        scp -o StrictHostKeyChecking=no target/*.jar ubuntu@${TARGET_EC2_IP}:${APP_DIR}/app.jar

                        # 3. Restart the application
                        # We use 'nohup' so the app keeps running after Jenkins disconnects
                        ssh -o StrictHostKeyChecking=no ubuntu@${TARGET_EC2_IP} "
                            pkill -f 'app.jar' || true
                            cd ${APP_DIR}
                            nohup java -jar app.jar > /dev/null 2>&1 &
                        "
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
