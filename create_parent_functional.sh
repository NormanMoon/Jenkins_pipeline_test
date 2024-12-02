#!/bin/bash

# Making a parent ticket functionally

#!/bin/bash
set -x

source "${WORKSPACE}"/lib/utils.sh


# Function to create a Jira JSON payload
create_jira_payload() {
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

# Function to send the Jira ticket creation request
create_jira_ticket() {
    local token="$1"
    local json_payload="$2"
    local output_file="$3"
    curl -v -i -X POST \
        -u "norman.moon@aboutobjects.com:$token" \
        -H "Content-Type:application/json" \
        -H "Accept: application/json" \
        -H "X-Atlassian-Token:no-check" \
        "https://normanmoon.atlassian.net/rest/api/2/issue/" \
        -d "$json_payload" \
        -o "$output_file"
}

# Main script logic
main() {
     local token="$1"
     local environment="$2"

     local project_id="10008" # Project ID for project POP
     local issue_type_id="10000" # Always the same for parent tickets
     local summary="Parent"
     local description="Parent"

     # Check environment and proceed if not in SQA or SQA-BETA
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

