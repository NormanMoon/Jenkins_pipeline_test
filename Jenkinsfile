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
                         rollback=params.ROLLBACK
                         rollback_tickets=params.TICKETS.split()
                         env=params.ENV
                         services=params.SERVICES.split()
                         sh "echo ${services}"
                         application=params.APPLICATION
                         app_version=params.APPLICATION_VERSION
                         release_type=params.RELEASE_TYPE
                    }
               }
          }
          stage('Creating Parent Ticket') {
               when { expression {!params.ROLLBACK} }
               steps {
                    script{
                         sh "bash create-parent-ticket-test.sh ${TOKEN}"
                    }
               }
          }
          stage('Creating Child Ticket') {
               when { expression {!params.ROLLBACK } }
               steps {
                    script{
                         sh "bash create-child-ticket-test.sh ${TOKEN} ${services} ${rollback} ${rollback_tickets}"
                    }
               }
          }
          stage('Updating Tickets') {
               when { expression {!params.ROLLBACK } }
               steps {
                    script{
                         sh "bash description-updater-test.sh ${TOKEN} ${env} ${application} ${app_version} ${release_type} ${rollback} ${rollback_tickets} ${services}"
                    }
               }
          }
          stage('Rollback Tickets') {
               when { expression {return params.ROLLBACK} }
               steps {
                    script {
                         sh "bash create-rollback-tickets.sh ${rollback_tickets}"
                    }
               }
          }
     }
}

