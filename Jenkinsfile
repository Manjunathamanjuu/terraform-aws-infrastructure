```groovy
pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
        ansiColor('xterm')
    }

    parameters {
        choice(
            name: 'ACTION',
            choices: ['plan', 'apply', 'destroy'],
            description: 'Select the Terraform action to perform'
        )
    }

    environment {
        TF_IN_AUTOMATION = 'true'
        CLOUDSDK_CORE_PROJECT = 'YOUR_GCP_PROJECT_ID'
        CLOUDSDK_COMPUTE_REGION = 'us-central1'
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('GCP Authentication & Terraform Validation') {
            steps {
                withCredentials([
                    file(
                        credentialsId: 'gcp-jenkins-credentials',
                        variable: 'GOOGLE_APPLICATION_CREDENTIALS'
                    )
                ]) {
                    sh '''
                        set -e

                        echo "======================================"
                        echo "GCP Authentication"
                        echo "======================================"

                        gcloud auth activate-service-account \
                          --key-file="$GOOGLE_APPLICATION_CREDENTIALS"

                        gcloud config set project "$CLOUDSDK_CORE_PROJECT"

                        echo ""
                        echo "======================================"
                        echo "GCP Identity"
                        echo "======================================"

                        gcloud auth list

                        echo ""
                        echo "======================================"
                        echo "GCP Project"
                        echo "======================================"

                        gcloud config get-value project

                        echo ""
                        echo "======================================"
                        echo "Terraform Version"
                        echo "======================================"

                        terraform version

                        echo ""
                        echo "======================================"
                        echo "Google Cloud CLI Version"
                        echo "======================================"

                        gcloud --version

                        echo ""
                        echo "======================================"
                        echo "Terraform Init"
                        echo "======================================"

                        terraform init -upgrade

                        echo ""
                        echo "======================================"
                        echo "Terraform Format Check"
                        echo "======================================"

                        terraform fmt -check -recursive

                        echo ""
                        echo "======================================"
                        echo "Terraform Validate"
                        echo "======================================"

                        terraform validate

                        echo ""
                        echo "======================================"
                        echo "GCP Setup & Validation Completed"
                        echo "======================================"
                    '''
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                withCredentials([
                    file(
                        credentialsId: 'gcp-jenkins-credentials',
                        variable: 'GOOGLE_APPLICATION_CREDENTIALS'
                    )
                ]) {
                    sh '''
                        set -e

                        echo "======================================"
                        echo "Terraform Plan - GCP"
                        echo "======================================"

                        terraform plan -out=tfplan

                        echo ""
                        echo "Terraform Plan Completed Successfully"
                    '''
                }
            }
        }

        stage('Approval') {
            when {
                expression {
                    return params.ACTION == 'apply' ||
                           params.ACTION == 'destroy'
                }
            }

            steps {
                script {
                    if (params.ACTION == 'apply') {
                        input(
                            message: 'Do you want to APPLY the GCP Terraform infrastructure?',
                            ok: 'Proceed'
                        )
                    } else {
                        input(
                            message: 'WARNING: Do you want to DESTROY the GCP Terraform infrastructure?',
                            ok: 'Proceed'
                        )
                    }
                }
            }
        }

        stage('Terraform Apply') {
            when {
                expression {
                    return params.ACTION == 'apply'
                }
            }

            steps {
                withCredentials([
                    file(
                        credentialsId: 'gcp-jenkins-credentials',
                        variable: 'GOOGLE_APPLICATION_CREDENTIALS'
                    )
                ]) {
                    sh '''
                        set -e

                        echo "======================================"
                        echo "Terraform Apply - GCP"
                        echo "======================================"

                        terraform apply -auto-approve tfplan

                        echo ""
                        echo "Terraform Apply Completed Successfully"
                    '''
                }
            }
        }

        stage('Terraform Destroy') {
            when {
                expression {
                    return params.ACTION == 'destroy'
                }
            }

            steps {
                withCredentials([
                    file(
                        credentialsId: 'gcp-jenkins-credentials',
                        variable: 'GOOGLE_APPLICATION_CREDENTIALS'
                    )
                ]) {
                    sh '''
                        set -e

                        echo "======================================"
                        echo "Terraform Destroy - GCP"
                        echo "======================================"

                        terraform destroy -auto-approve

                        echo ""
                        echo "Terraform Destroy Completed Successfully"
                    '''
                }
            }
        }

        stage('Terraform Outputs') {
            when {
                expression {
                    return params.ACTION == 'apply'
                }
            }

            steps {
                withCredentials([
                    file(
                        credentialsId: 'gcp-jenkins-credentials',
                        variable: 'GOOGLE_APPLICATION_CREDENTIALS'
                    )
                ]) {
                    sh '''
                        set -e

                        echo "======================================"
                        echo "Terraform Outputs - GCP"
                        echo "======================================"

                        terraform output

                        echo ""
                        echo "Terraform Outputs Retrieved Successfully"
                    '''
                }
            }
        }
    }

    post {
        success {
            echo "======================================"
            echo "GCP Terraform Pipeline Completed Successfully"
            echo "======================================"
        }

        failure {
            echo "======================================"
            echo "GCP Terraform Pipeline Failed"
            echo "Please check the Jenkins console logs."
            echo "======================================"
        }

        aborted {
            echo "======================================"
            echo "GCP Terraform Pipeline Aborted"
            echo "======================================"
        }

        always {
            sh '''
                rm -f tfplan 2>/dev/null || true
            '''
        }
    }
}
```
