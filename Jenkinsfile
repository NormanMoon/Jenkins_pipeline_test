pipeline {
    agent any

     environment {
        TOKEN=credentials('Jira_Token')
    }

        stages {
            stage('Parameter Setup') {
                steps {
                    script {
                        // Formats the parameters
                        env=params.ENV
                        services=params.SERVICES.split()
                        sh "echo ${services}"
                        application=params.APPLICATION
                        app_version=params.APPLICATION_VERSION
                        release_type=params.RELEASE_TYPE
                    }
                }
            }
            stage('Checkout') {
                steps {
                    // Get some code from a GitHub repository
                    git branch: "main", url: "https://github.com/NormanMoon/Jenkins_pipeline_test.git"

                }
            }
            stage('Creating Parent Ticket') {
                steps {
                    script{
                        sh "bash create-parent-ticket-test.sh ${TOKEN}"
                    }

                }
            }
            stage('Creating Child Ticket') {
                steps {
                    script{
                        sh "bash create-child-ticket-test.sh ${TOKEN} ${services}"
                    }
                }
            }
            stage('Updating Tickets') {
                steps {
                    script{
                        sh "bash description-updater-test.sh ${TOKEN} ${env} ${application} ${app_version} ${release_type} ${services}"
                    }
                }
            }
    }
}

