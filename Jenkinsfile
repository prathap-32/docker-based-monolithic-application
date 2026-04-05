pipeline {
    agent any

    environment {
        KUBECONFIG = "/var/lib/jenkins/.kube/config"
        IMAGE_NAME = "prathap32/web-app"
        IMAGE_TAG = "${BUILD_NUMBER}"
    }

    stages {
        stage('Clone Source Code') {
            steps {
                git branch: 'main', url: 'https://github.com/prathap-32/docker-based-monolithic-application.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t $IMAGE_NAME:$IMAGE_TAG .'
                sh 'docker tag $IMAGE_NAME:$IMAGE_TAG $IMAGE_NAME:latest'
            }
        }

        stage('Push Docker Image') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-creds',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh '''
                    echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                    docker push $IMAGE_NAME:$IMAGE_TAG
                    docker push $IMAGE_NAME:latest
                    docker logout
                    '''
                }
            }
        }

        stage('Check Kubernetes Connection') {
            steps {
                sh 'kubectl get nodes'
            }
        }

        stage('Apply Services Always') {
            steps {
                sh '''
                kubectl apply -f k8s/mysql-service.yaml
                kubectl apply -f k8s/web-app-service.yaml
                '''
            }
        }

        stage('Deploy MySQL If Not Found') {
            steps {
                script {
                    def mysqlExists = sh(
                        script: 'kubectl get deployment mysql-db --ignore-not-found -o name',
                        returnStdout: true
                    ).trim()

                    if (!mysqlExists) {
                        sh '''
                        kubectl apply -f k8s/mysql-secret.yaml
                        kubectl apply -f k8s/web-app-configmap.yaml
                        kubectl apply -f k8s/mysql-initdb-configmap.yaml
                        kubectl apply -f k8s/mysql-deployment.yaml
                        '''
                    } else {
                        echo 'MySQL deployment already exists, skipping MySQL creation'
                    }
                }
            }
        }

        stage('Apply Web App Deployment Always') {
            steps {
                sh '''
                kubectl apply -f k8s/web-app-configmap.yaml
                kubectl apply -f k8s/web-app-deployment.yaml
                '''
            }
        }

        stage('Update Web App Image') {
            steps {
                sh 'kubectl set image deployment/web-app web-app=$IMAGE_NAME:$IMAGE_TAG'
            }
        }

        stage('Wait for Web App Rollout') {
            steps {
                sh 'kubectl rollout status deployment/web-app'
            }
        }

        stage('Verify Deployment') {
            steps {
                sh '''
                kubectl get pods
                kubectl get svc
                '''
            }
        }
    }

    post {
        success {
            echo 'CI/CD pipeline completed successfully'
        }
        failure {
            echo 'CI/CD pipeline failed'
        }
    }
}
