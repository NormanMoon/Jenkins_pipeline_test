#!/bin/bash

# Making a parent ticket functionally

#!/bin/bash
set -x

source "${WORKSPACE}"/lib/utils.sh


# Function to create the Jira JSON for a parent ticket
create_json_string() {
    local summary="$1"
    local project_id="$2"
    local issue_type_id="$3"
    local description="$4"
    printf '{
       "fields": {
         "summary": "%s",
         "project": {
           "id": "%s"
         },
         "issuetype": {
           "id": "%s"
         },
         "description": "%s"
       }
     }' "$summary" \
     "$project_id" \
     "$issue_type_id" \
     "$description"
}

# Main script logic
main() {
     local token="$1"
     local environment="$2"

     local project_id="10008" # Project ID for project POP
     local issue_type_id="10000" # Always the same for parent tickets
     local summary="Parent"
     local description="Parent"

     # Check environment and proceed if not in SQA or SQA-beta
     if [[ "${environment,,}" != "sqa" ]] && [[ "${environment,,}" != "sqa-beta" ]]; then
        local json_payload
        json_payload=$(create_jira_payload "$summary" "$project_id" "$issue_type_id" "$description")
        create_jira_ticket "$token" "$json_payload" "create-parent-ticket-test.out"
     fi

     # Output the created ticket file
     cat create-parent-ticket-test.out
}

# Call main with all script arguments
main "$@"

