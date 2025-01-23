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
                         application=params.APPLICATION
                         app_version=params.APPLICATION_VERSION
                         release_type=params.RELEASE_TYPE
                         vault_ticket_description = "\"${params.VAULT_DESCRIPTION}\""
                         rollback=params.ROLLBACK
                         rollback_tickets=params.ROLLBACK_TICKETS.split()
                         ticket_description_change=params.TICKET_DESCRIPTION_CHANGE_LIST.split()
                    }
               }
          }
          stage('Creating Parent Ticket') {
               when { expression {!params.ROLLBACK && params.TICKET_DESCRIPTION_CHANGE_LIST.isEmpty()} }
               steps {
                    script{
                         sh "bash src/scripts/parent-ticket-config.sh ${TOKEN} ${application} ${env}"
                    }
               }
          }
          stage('Creating Child Ticket') {
               when { expression {!params.ROLLBACK && params.TICKET_DESCRIPTION_CHANGE_LIST.isEmpty()} }
               steps {
                    script{
                         sh "bash src/scripts/child-ticket-config.sh ${TOKEN} ${env} ${application} ${services}"
                    }
               }
          }
          stage('Updating Tickets') {
               when { expression {!params.ROLLBACK && params.TICKET_DESCRIPTION_CHANGE_LIST.isEmpty()} }
               steps {
                    script{
                         sh "bash src/scripts/ticket-description-summary-populator.sh ${TOKEN} ${env} ${application} ${app_version} ${release_type} ${vault_ticket_description} ${services} "
                    }
               }
          }
          stage('Changing Ticket Order and Discription') {
               when { expression {!params.TICKET_DESCRIPTION_CHANGE_LIST.isEmpty()}}
                    steps {
                          sh "bash src/scripts/ticket-description-changer.sh ${TOKEN} ${env} ${application} ${app_version} ${release_type} ${vault_ticket_description} ${services} ${ticket_description_change}"
                    }
          }
     }
}

