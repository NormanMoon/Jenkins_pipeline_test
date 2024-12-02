
get_project_id() {
     echo "10008"
}

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

# This cleans one service
clean_one_service() {
     local service=$1
     echo "${service//[\[\],]/}"
}

# Uses the map function and the clean_one_service function to clean all services
clean_all_services() {
     local services=("$@")
     map clean_one_service "${services[@]}"
}

# Function to send the Jira ticket creation request
create_jira_ticket() {
    local token="$1"
    local json_string="$2"
    local output_file="$3"
    curl -v -i -X POST \
        -u "norman.moon@aboutobjects.com:$token" \
        -H "Content-Type:application/json" \
        -H "Accept: application/json" \
        -H "X-Atlassian-Token:no-check" \
        "https://normanmoon.atlassian.net/rest/api/2/issue/" \
        -d "$json_string" \
        -o "$output_file"
}

modify_services_for_smartfhir_deployment() {
     local services=("$@")
     local modified_services=()

     for service in "${services[@]}"; do
          if [ "${service,,}" != "deployment" ]; then
               modified_services+=("$service")
          fi
     done
     modified_services+=("Main" "HFD")

     echo "${modified_services[@]}"
}

task_or_bug() {
     local issue_type_id=$1
     if ((issue_type_id==10008)); then
          echo "Task"
     elif ((issue_type_id==10011)); then
          echo "Bug"
     fi
}

issue_type_based_off_of_service() {
     local service=$1
     echo "Determining issue type for service: $service" >&2  # Debug line
     if [[ "${service,,}" = "deployment" ]] || [[ "${service,,}" = "main" ]] || [[ "${service,,}" = "hfd" ]]; then
          task_or_bug "10011"
     else
          task_or_bug "10008"
     fi
}

get_all_issue_types() {
     local services=("$@")
     local list_of_issue_types
     list_of_issue_types=$(map issue_type_based_off_of_service "${services[@]}")
     echo "${list_of_issue_types[@]}"
}

get_parent_ticket() {
     local environment=$1
     local application=$2
     local parent_ticket
     if [[ "${environment,,}" == "sqa" ]] || [[ "${environment,,}" == "sqa-beta" ]]; then
          if [[ "${application,,}" == "smartfhir" ]]; then
               parent_ticket="POP-5"
          elif [[ "${application,,}" == "federator" ]]; then
               parent_ticket="POP-4"
          elif [[ "${application,,}" == "mirth" ]]; then
               parent_ticket="POP-3"
          elif [[ "${application,,}" == "governance-client" ]] || [[ "${application,,}" == "governance-service" ]]; then
               parent_ticket="POP-6"
          fi
     else
          parent_ticket=$(awk -F'"' '/"key":/ {print $8}' create-parent-ticket-test.out)
     fi
     echo "${parent_ticket}"
}
