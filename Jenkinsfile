pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
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
        TF_INPUT = 'false'
        AWS_DEFAULT_REGION = 'us-east-1'
        AWS_REGION = 'us-east-1'
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('AWS Authentication & Terraform Validation') {
            steps {
                script {
                    bat '''
                        @echo off
                        echo ======================================
                        echo Terraform Version
                        echo ======================================
                        terraform version
                        if errorlevel 1 exit /b 1

                        echo.
                        echo ======================================
                        echo Terraform Init
                        echo ======================================
                        terraform init -input=false
                        if errorlevel 1 exit /b 1

                        echo.
                        echo ======================================
                        echo Terraform Format Check
                        echo ======================================
                        terraform fmt -check -recursive
                        if errorlevel 1 exit /b 1

                        echo.
                        echo ======================================
                        echo Terraform Validate
                        echo ======================================
                        terraform validate
                        if errorlevel 1 exit /b 1
                    '''

                    withCredentials([
                        [$class: 'AmazonWebServicesCredentialsBinding',
                         credentialsId: 'aws-jenkins-credentials']
                    ]) {
                        bat '''
                            @echo off
                            echo ======================================
                            echo AWS Authentication
                            echo ======================================
                            aws sts get-caller-identity
                            if errorlevel 1 exit /b 1

                            echo.
                            echo AWS CLI Version
                            aws --version
                            if errorlevel 1 exit /b 1
                        '''
                    }
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                withCredentials([
                    [$class: 'AmazonWebServicesCredentialsBinding',
                     credentialsId: 'aws-jenkins-credentials']
                ]) {
                    script {
                        if (params.ACTION == 'destroy') {
                            bat '''
                                @echo off
                                echo ======================================
                                echo Terraform Destroy Plan - AWS
                                echo ======================================
                                terraform plan -destroy -input=false -out=tfplan
                                if errorlevel 1 exit /b 1
                                terraform show -no-color tfplan
                            '''
                        } else {
                            bat '''
                                @echo off
                                echo ======================================
                                echo Terraform Plan - AWS
                                echo ======================================
                                terraform plan -input=false -out=tfplan
                                if errorlevel 1 exit /b 1
                                terraform show -no-color tfplan
                            '''
                        }
                    }
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
                            message: 'Review the plan. Do you want to APPLY the AWS infrastructure changes?',
                            ok: 'Approve Apply'
                        )
                    } else {
                        input(
                            message: 'WARNING: This will destroy the resources in the saved plan. Continue?',
                            ok: 'Approve Destroy'
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
                    [$class: 'AmazonWebServicesCredentialsBinding',
                     credentialsId: 'aws-jenkins-credentials']
                ]) {
                    bat '''
                        @echo off
                        echo ======================================
                        echo Terraform Apply - AWS
                        echo ======================================
                        terraform apply -input=false -auto-approve tfplan
                        if errorlevel 1 exit /b 1
                        echo Terraform Apply Completed Successfully
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
                    [$class: 'AmazonWebServicesCredentialsBinding',
                     credentialsId: 'aws-jenkins-credentials']
                ]) {
                    bat '''
                        @echo off
                        echo ======================================
                        echo Terraform Destroy - AWS
                        echo ======================================
                        terraform apply -input=false -auto-approve tfplan
                        if errorlevel 1 exit /b 1
                        echo Terraform Destroy Completed Successfully
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
                    [$class: 'AmazonWebServicesCredentialsBinding',
                     credentialsId: 'aws-jenkins-credentials']
                ]) {
                    bat '''
                        @echo off
                        echo ======================================
                        echo Terraform Outputs - AWS
                        echo ======================================
                        terraform output
                        if errorlevel 1 exit /b 1
                    '''
                }
            }
        }
    }

    post {
        success {
            echo '======================================'
            echo 'AWS Terraform Pipeline Completed Successfully'
            echo '======================================'
        }

        failure {
            echo '======================================'
            echo 'AWS Terraform Pipeline Failed'
            echo 'Check the Jenkins Console Output.'
            echo '======================================'
        }

        aborted {
            echo 'AWS Terraform Pipeline Aborted'
        }

        always {
            bat(
                returnStatus: true,
                script: '@if exist tfplan del /q tfplan'
            )
        }
    }
}