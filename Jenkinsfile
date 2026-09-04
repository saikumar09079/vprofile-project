pipeline {

    agent any
      tools {
        jdk 'java'
        maven 'Maven-3.8.4'
    } 
    environment {

        DOCKER_IMAGE = "sai090793/myapp"
        DOCKER_TAG   = "${BUILD_NUMBER}"

        DOCKER_CREDS = credentials('dockerhub-credentials')

    }

    stages {

        stage('Check Tools') {
    steps {
        sh '''
            echo "JAVA_HOME=$JAVA_HOME"
            echo "MAVEN_HOME=$MAVEN_HOME"
            which java
            java -version
            which mvn
            mvn -version
        '''
    }
}

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Maven Build') {
            steps {
                sh 'mvn clean package -DskipTests=false'
            }
        }

        stage('Unit Test') {
            steps {
                sh 'mvn test'
            }
        }

        stage('SonarQube Analysis') {
            steps {

                withSonarQubeEnv('SonarQube') {

                    sh '''
                        mvn sonar:sonar \
                        -Dsonar.projectKey=my-java-app \
                        -Dsonar.projectName=my-java-app
                    '''
                }
            }
        }

        stage('Quality Gate') {
            steps {

                timeout(time: 5, unit: 'MINUTES') {

                    waitForQualityGate abortPipeline: true

                }
            }
        }

        stage('Docker Build') {
            steps {

                sh '''
                    docker build \
                    -t ${DOCKER_IMAGE}:${DOCKER_TAG} \
                    -t ${DOCKER_IMAGE}:latest .
                '''
            }
        }

        stage('Docker Login') {
            steps {

                sh '''
                    echo "$DOCKER_CREDS_PSW" | \
                    docker login \
                    -u "$DOCKER_CREDS_USR" \
                    --password-stdin
                '''
            }
        }

        stage('Docker Push') {
            steps {

                sh '''
                    docker push ${DOCKER_IMAGE}:${DOCKER_TAG}
                    docker push ${DOCKER_IMAGE}:latest
                '''
            }
        }

        stage('Deploy to EC2') {

            steps {

                sshagent(credentials: ['deployment-ssh']) {

                    sh '''
                        ssh -o StrictHostKeyChecking=no \
                        ec2-user@172.31.43.96 \
                        "
                        docker pull ${DOCKER_IMAGE}:latest &&
                        docker stop myapp || true &&
                        docker rm myapp || true &&
                        docker run -d \
                            --name myapp \
                            -p 8081:8080 \
                            ${DOCKER_IMAGE}:latest
                        "
                    '''
                }
            }
        }
    }

    post {

        success {
            echo 'CI/CD pipeline completed successfully.'
        }

        failure {
            echo 'CI/CD pipeline failed.'
        }
    }
}
