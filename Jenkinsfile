pipeline {
    agent any

    tools {
        jdk 'jdk17'
        maven 'maven3'
    }

    environment {
        PROJECT_KEY = "enterprise-ci-java-service"

        NEXUS_URL   = "http://16.170.234.113:30081"
        NEXUS_REPO  = "maven-snapshots"

        AWS_REGION      = "eu-north-1"
        AWS_ACCOUNT_ID  = "220309168382"
        ECR_REPO        = "enterprise-ci-java-service"
    }

    stages {

        // ================= CHECKOUT =================
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        // ================= BUILD =================
        stage('Build & Package') {
            steps {
                configFileProvider([configFile(fileId: 'nexus-settings', variable: 'MAVEN_SETTINGS')]) {
                    sh "mvn -B -s $MAVEN_SETTINGS clean package -DskipTests"
                }
            }
        }

        // ================= SONAR =================
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

        // ================= QUALITY GATE =================
        stage('Quality Gate') {
            steps {
                timeout(time: 10, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        // ================= UPLOAD TO NEXUS =================
        stage('Upload Artifact to Nexus') {
            steps {
                withCredentials([usernamePassword(
                        credentialsId: 'nexus-creds-v3',
                        usernameVariable: 'NEXUS_USER',
                        passwordVariable: 'NEXUS_PASS'
                )]) {

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

        // ================= BUILD DOCKER =================
        stage('Build Docker Image') {
            steps {
                withCredentials([usernamePassword(
                        credentialsId: 'nexus-creds-v3',
                        usernameVariable: 'USER',
                        passwordVariable: 'PASS'
                )]) {

                    script {
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

        // ================= PUSH TO ECR =================
        stage('Push Docker Image to ECR') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-ecr-creds'
                ]]) {

                    script {

                        def ecrUri = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}"

                        sh """
                            echo "Logging into AWS ECR..."
                            aws ecr get-login-password --region ${AWS_REGION} | \
                            docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

                            echo "Tagging Docker Image..."
                            docker tag ${PROJECT_KEY}:latest ${ecrUri}:latest
                            docker tag ${PROJECT_KEY}:latest ${ecrUri}:${BUILD_NUMBER}

                            echo "Pushing Docker Images..."
                            docker push ${ecrUri}:latest
                            docker push ${ecrUri}:${BUILD_NUMBER}
                        """
                    }
                }
            }
        }
    }

    // ================= POST =================
    post {
        success {
            echo "✅ Full CI/CD Pipeline Completed Successfully!"
        }
        failure {
            echo "❌ Pipeline Failed! Check logs."
        }
    }
}
