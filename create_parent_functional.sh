#!/bin/bash

# Making a parent ticket functionally

#!/bin/bash
set -x

# Writing a map function, that takes a function, and applies it to every element of an array
map() {
     local func_to_apply=$1 # Passed in function argument
     shift #Shift is used because we no longer need the $1 argument
     local elements=("$@") # An array of the passed in arguments after shift
     local return_result=() # The array to hold the changed elements
     # for loop that goes through all the elements in the array elements
     for element in "${elements[@]}"; do
          # Calls the function func_to_apply on the current element and saves the result in the array return_result

          # The outside ("$ ...") is used to capture the result of ($func_to_apply "$element")
          return_result+=("$($func_to_apply "$element")")
     done

     # returns the array with the transformed elements, seperated by spaces
     echo "${return_result[@]}"
}

clean_one_service() {
     local service=$1
     echo"${service//[\[\],]/}"
}

clean_all_services() {
     local services=("$@")
     map clean_one_service "${services[@]}"
}

# Function to validate services against application rules
validate_services() {
    local application="$1"
    shift
    local services=("$@")
    for service in "${services[@]}"; do
        if [[ "${service,,}" =~ ^(hfd|main|archive)$ && "${application,,}" != "smartfhir" ]]; then
            echo "You are creating HFD, Main, and Archive tickets, but your application is no Smartfhir!" >&2
            return 1
        fi
    done
    return 0
}

# Function to create a Jira JSON payload
create_jira_payload() {
    local summary="$1"
    local project_id="$2"
    local issuetype_id="$3"
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
     }' "$summary" "$project_id" "$issuetype_id" "$description"
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
     local application="$2"
     local environment="$3"
     shift 3
     local services=()
     IFS=' ' read -r -a services <<< "$@"
     local project_id="10008" # Project ID for project POP
     local issuetype_id="10000" # Always the same for parent tickets
     local summary="Parent"
     local description="Parent"

     # Clean up the services
     services=($(clean_services "${services[@]}"))

     # Validate the services
     if ! validate_services "$application" "${services[@]}"; then
        exit 1
     fi

     # Check environment and proceed if not in SQA or SQA-BETA
     if [[ "${environment,,}" != "sqa" ]] && [[ "${environment,,}" != "sqa-beta" ]]; then
        local json_payload
        json_payload=$(create_jira_payload "$summary" "$project_id" "$issuetype_id" "$description")
        create_jira_ticket "$token" "$json_payload" "create-parent-ticket-test.out"
     fi

     # Output the created ticket file
     cat create-parent-ticket-test.out
}

# Call main with all script arguments
main "$@"

