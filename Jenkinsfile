pipeline {
    agent {
        kubernetes {
            yaml '''
                apiVersion: v1
                kind: Pod
                spec:
                  serviceAccountName: jenkins
                  containers:
                  - name: kaniko
                    image: gcr.io/kaniko-project/executor:debug
                    command:
                    - sleep
                    args:
                    - 99d
                    volumeMounts:
                    - name: docker-config
                      mountPath: /kaniko/.docker
                  - name: git
                    image: alpine/git:latest
                    command:
                    - sleep
                    args:
                    - 99d
                  - name: aws-cli
                    image: amazon/aws-cli:latest
                    command:
                    - sleep
                    args:
                    - 99d
                  volumes:
                  - name: docker-config
                    emptyDir: {}
            '''
        }
    }

    environment {
        AWS_REGION = 'eu-central-1'
        ECR_REPOSITORY = 'goit-devops-app'
        IMAGE_TAG = "${BUILD_NUMBER}"
        GIT_BRANCH = 'lesson-9'
        // ECR_REGISTRY and AWS_ACCOUNT_ID are set dynamically in 'Setup Environment' stage
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Setup Environment') {
            steps {
                container('aws-cli') {
                    script {
                        // Dynamically get AWS Account ID - no hardcoding needed
                        env.AWS_ACCOUNT_ID = sh(
                            script: 'aws sts get-caller-identity --query Account --output text',
                            returnStdout: true
                        ).trim()
                        env.ECR_REGISTRY = "${env.AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

                        echo "AWS Account ID: ${env.AWS_ACCOUNT_ID}"
                        echo "ECR Registry: ${env.ECR_REGISTRY}"
                    }
                }
            }
        }

        stage('Get ECR Login') {
            steps {
                container('aws-cli') {
                    script {
                        // Get ECR login token - use WORKSPACE (shared between containers)
                        sh '''
                            aws ecr get-login-password --region ${AWS_REGION} > ${WORKSPACE}/ecr-password
                        '''
                    }
                }
            }
        }

        stage('Setup Kaniko Auth') {
            steps {
                container('kaniko') {
                    script {
                        // Create docker config for ECR - read from shared WORKSPACE
                        // IMPORTANT: Use 'tr -d' to remove newlines from base64 output
                        // BusyBox base64 wraps at 76 chars, which breaks JSON parsing
                        sh '''
                            ECR_PASSWORD=$(cat ${WORKSPACE}/ecr-password)
                            AUTH=$(echo -n "AWS:${ECR_PASSWORD}" | base64 | tr -d '\n')

                            cat > /kaniko/.docker/config.json << EOF
{
    "auths": {
        "${ECR_REGISTRY}": {
            "auth": "${AUTH}"
        }
    }
}
EOF
                        '''
                    }
                }
            }
        }

        stage('Build and Push Image') {
            steps {
                container('kaniko') {
                    sh '''
                        /kaniko/executor \
                            --context=${WORKSPACE} \
                            --dockerfile=${WORKSPACE}/Dockerfile \
                            --destination=${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG} \
                            --destination=${ECR_REGISTRY}/${ECR_REPOSITORY}:latest
                    '''
                }
            }
        }

        stage('Update Values File') {
            steps {
                container('git') {
                    withCredentials([usernamePassword(
                        credentialsId: 'github-credentials',
                        usernameVariable: 'GIT_USERNAME',
                        passwordVariable: 'GIT_PASSWORD'
                    )]) {
                        sh '''
                            git config --global user.email "jenkins@example.com"
                            git config --global user.name "Jenkins CI"

                            # Update image tag in values.yaml
                            sed -i "s/tag: .*/tag: \\"${IMAGE_TAG}\\"/" charts/django-app/values.yaml

                            # Commit and push
                            git add charts/django-app/values.yaml
                            git commit -m "Update image tag to ${IMAGE_TAG}"

                            # Get repo URL dynamically from git remote (removes https://)
                            REPO_URL=$(git config --get remote.origin.url | sed 's|https://||')

                            # Push using credentials
                            git push https://${GIT_USERNAME}:${GIT_PASSWORD}@${REPO_URL} HEAD:${GIT_BRANCH}
                        '''
                    }
                }
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully!'
            echo "New image: ${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}"
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}