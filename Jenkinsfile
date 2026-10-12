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
                            echo Cleaning local Terraform initialization cache
                            if exist .terraform rmdir /s /q .terraform
                            if exist .terraform (
                                echo ERROR: Could not remove .terraform directory
                                exit /b 1
                            )

                            echo.
                            echo Terraform Init
                            terraform init -input=false -no-color
                            if errorlevel 1 exit /b 1

                            echo.
                            echo Terraform Format Check
                            terraform fmt -check -recursive
                            if errorlevel 1 exit /b 1

                            echo.
                            echo Terraform Validate
                            terraform validate -no-color
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
                                terraform plan -destroy -input=false -no-color -out=tfplan
                                if errorlevel 1 exit /b 1

                                echo.
                                echo Reviewing saved destroy plan
                                terraform show -no-color tfplan
                                if errorlevel 1 exit /b 1
                            '''
                        } else {
                            bat '''
                                @echo off
                                echo Terraform Plan - AWS
                                terraform plan -input=false -no-color -out=tfplan
                                if errorlevel 1 exit /b 1

                                echo.
                                echo Reviewing saved plan
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
                            message: 'Review the Terraform plan in Console Output. Approve AWS infrastructure changes?',
                            ok: 'Approve Apply'
                        )
                    } else {
                        input(
                            message: 'WARNING: Review the destroy plan carefully. Approve destruction of the resources in the saved plan?',
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
                        terraform apply -input=false -no-color -auto-approve tfplan
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
                        terraform apply -input=false -no-color -auto-approve tfplan
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

