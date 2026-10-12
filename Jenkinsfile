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
        stage('AWS Authentication & Terraform Validation') {
            steps {
                script {
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

                            echo.
                            echo Terraform Version
                            terraform version
                            if errorlevel 1 exit /b 1

                            echo.
                            echo Terraform Init
                            terraform init -input=false
                            if errorlevel 1 exit /b 1

                            echo.
                            echo Terraform Format Check
                            terraform fmt -check -recursive
                            if errorlevel 1 exit /b 1

                            echo.
                            echo Terraform Validate
                            terraform validate
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
                                echo Terraform Destroy Plan - AWS
                                terraform plan -destroy -input=false -out=tfplan
                                if errorlevel 1 exit /b 1
                                terraform show -no-color tfplan
                                if errorlevel 1 exit /b 1
                            '''
                        } else {
                            bat '''
                                @echo off
                                echo Terraform Plan - AWS
                                terraform plan -input=false -out=tfplan
                                if errorlevel 1 exit /b 1
                                terraform show -no-color tfplan
                                if errorlevel 1 exit /b 1
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
                            message: 'Review the plan. Approve AWS infrastructure changes?',
                            ok: 'Approve Apply'
                        )
                    } else {
                        input(
                            message: 'WARNING: Approve destruction of the resources in the saved plan?',
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
                        echo Terraform Apply - AWS
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
                        echo Terraform Destroy - AWS
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
                        echo Terraform Outputs - AWS
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
            echo 'Pipeline execution finished.'
        }
    }
}