pipeline {
    agent {
        node {
            label 'AGENT-1'
        }
    } 
    options {
        disableConcurrentBuilds()
        ansiColor('xterm')
        timeout(time: 1, unit: 'HOURS')
    }
    environment {
    TF_PLUGIN_CACHE_DIR = "/opt/terraform-plugin-cache"
    }
    parameters {
        string(name: 'VERSION', defaultValue: '', description: 'What is the Version?')

        string(name: 'ENVIRONMENT', defaultValue: '', description: 'Specify the target Environment?')

        choice(name: 'ACTION', choices: ['apply', 'destroy'], description: 'Pick something')
    }
    stages {
        stage('Get the Package Version & Environment from USER-CI') {
            steps {
                echo "Version: ${params.VERSION}"

                echo "environment: ${params.ENVIRONMENT}"
            }
        }
        stage('Terraform Initializing') {
            steps {
                sh """
                    cd terraform
                    terraform init --backend-config=${params.ENVIRONMENT}/backend.tf -reconfigure
                """
            }
        }
        stage('Terraform Planning') {
            steps {
                sh """
                    cd terraform
                    terraform plan -var-file=${params.ENVIRONMENT}/${params.ENVIRONMENT}.tfvars -var="app_version=${params.VERSION}"
                """
            }
        }
        stage('Terraform Apply') {
            when {
                expression {
                    "${params.ACTION}" == 'apply'
                }
            }
            steps {
                sh """
                    cd terraform
                    terraform apply -var-file=${params.ENVIRONMENT}/${params.ENVIRONMENT}.tfvars -var="app_version=${params.VERSION}" -auto-approve
                """
            }
        }
        stage('Destroying') {
            when {
                expression {
                    "${params.ACTION}" == 'destroy'
                }
            }
            steps {
                sh """
                    cd terraform
                    terraform destroy -var-file=${params.ENVIRONMENT}/${params.ENVIRONMENT}.tfvars -var="app_version=${params.VERSION}" -auto-approve
                """
            }
        }
    }
    post {
        always {
            echo 'PIPELINE EXECUTION IS COMPLETED'
        }
        failure {
            echo 'The pipeline is FAILED'
        }
        success {
            echo 'The pipeline is SUCESS'
        }
    }
}