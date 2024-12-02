#!/bin/bash

# Making a parent ticket functionally

#!/bin/bash
set -x

source "${WORKSPACE}"/lib/utils.sh

creat_json_string_for_bug() {
     local summary=$1
     local project_id=$2
     local issue_type_id=$3
     local parent_ticket_id=$4
     local description=$5

     printf '{

          "fields": {
               "summary": "%s",
               "project": {
                    "id": "%s"
               },
               "issuetype": {
                  "id": "%s"
               },
               "parent": {
                  "key": "%s"
               },
          "description": "%s"
          }
     }'   "$summary" \
          "$project_id" \
          "$issue_type_id" \
          "$parent_ticket_id" \
          "$description"
}

creat_json_string_for_task() {
     local summary=$1
     local project_id=$2
     local issue_type_id=$3
     local parent_ticket_id=$4
     local description=$5

     printf '{

          "fields": {
               "summary": "%s",
               "project": {
                    "id": "%s"
               },
               "issuetype": {
                  "id": "%s"
               },
               "parent": {
                  "key": "%s"
               },
          "description": "%s"
          }
     }'   "$summary" \
          "$project_id" \
          "$issue_type_id" \
          "$parent_ticket_id" \
          "$description"
}

main() {
     local token="$1"
     local env="$2"
     local application="$3"
     shift 3
     local services=("$@")
     local project_id
     project_id=$(get_project_id)
     local cleaned_services=()
     local issue_type_ids=()
     local parent_ticket
     parent_ticket=$(get_parent_ticket "$env" "$application")
     # shellcheck disable=SC2207
     cleaned_services=($(clean_all_services "${services[@]}"))

     # shellcheck disable=SC2207
     issue_type_ids=($(return_list_of_issue_type_ids "${cleaned_services[@]}"))

     for i in "${issue_type_ids[@]}"; do
          echo "issue_type_id: $i"
     done


     for issue_type in "${issue_type_ids[@]}"; do
          local current_issue_type
          current_issue_type=$(task_or_bug "$issue_type")
          local json_payload
          if [[ "${current_issue_type,,}" = "bug" ]]; then
               json_payload=$(create_json_string_for_bug "$summary" "$project_id" "$issue_type" "$parent_ticket" "bug")
          elif [[ "${current_issue_type,,}" = "task" ]]; then
               json_payload=$(create_json_string_for_task "$summary" "$project_id" "$issue_type" "$parent_ticket" "task")
          fi
          create_jira_ticket "$token" "$json_payload" "create-child-ticket-test-subtask.out"
     done

     cat create-child-ticket-subtask.out
}

main "$@"

