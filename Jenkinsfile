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
                         sh "bash create_parent_functional.sh ${TOKEN} ${application} ${env}"
                    }
               }
          }
          stage('Creating Child Ticket') {
               when { expression {params.ROLLBACK && params.TICKET_DESCRIPTION_CHANGE_LIST.isEmpty()} }
               steps {
                    script{
                         sh "bash create-child-ticket-test.sh ${TOKEN} ${env} ${application} ${services}"
                    }
               }
          }
          stage('Updating Tickets') {
               when { expression {params.ROLLBACK && params.TICKET_DESCRIPTION_CHANGE_LIST.isEmpty()} }
               steps {
                    script{
                         sh "bash description-updater-test.sh ${TOKEN} ${env} ${application} ${app_version} ${release_type} ${vault_ticket_description} ${services}"
                    }
               }
          }
          stage('Rollback Tickets') {
               when { expression {return params.ROLLBACK && params.TICKET_DESCRIPTION_CHANGE_LIST.isEmpty()} }
               steps {
                    script {
                         sh "bash create-rollback-tickets.sh ${TOKEN} ${rollback_tickets}"
                    }
               }
          }
          stage('Changing Ticket Description') {
               when { expression {!params.TICKET_DESCRIPTION_CHANGE_LIST.isEmpty()} }
               steps {
                    script{
                         def ticket_description_changes=params.TICKET_DESCRIPTION_CHANGE_LIST.split('\n')
                         def list_services=params.SERVICES.split('\n')
                         sh """
                                     bash change-ticket-description.sh \
                                         ${TOKEN} \
                                         ${env} \
                                         ${application} \
                                         ${app_version} \
                                         ${release_type} \
                                         ${vault_ticket_description} \
                                         '${list_services.join(' ')}' \
                                         '${ticket_description_changes.join(' ')}'
                                     """
                    }
               }
          }
     }
}

