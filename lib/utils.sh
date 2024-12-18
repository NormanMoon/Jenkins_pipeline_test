
get_project_id() {
     echo "10008"
}

get_project_prefix() {
     echo "POP-"
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
     local application=$1
     shift
     local services=("$@")
     # shellcheck disable=SC2207
     local clean_services=($(map clean_one_service "${services[@]}"))
     if_smartfhir_then_modify_services_for_deployment_service "$application" "${clean_services[@]}"
}

get_number_of_services() {
     local services=("$@")
     echo ${#services[@]}
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

edit_description_of_jira_ticket() {
     local token="$1"
     local json_string="$2"
     local ticket="$3"
     local output_file="$4"
     curl -v -i -X POST \
          -u "norman.moon@aboutobjects.com:$token" \
          -H "Content-Type:application/json" \
          -H "Accept: application/json" \
          -H "X-Atlassian-Token:no-check" \
          "https://normanmoon.atlassian.net/rest/api/2/issue/${ticket}" \
          -d "$json_string" \
          -o "$output_file"
}

get_image() {
     local application=$1
     local image # This is the image that will be used in the ticket summary
     if [ "${application,,}" = "federator" ]; then
          image=" pghd-fhir-federator"
     elif [ "${application,,}" = "smartfhir" ]; then
          image="smart-pgd-fhir-service"
     elif [ "${application,,}" = "mirth" ] && { [ "${env,,}" = "prod" ] || [ "${env,,}" = "sqa" ]; } then
          image="tmc-v2"
     elif [ "${application,,}" = "mirth" ] && { [ "${env,,}" = "prod-beta" ] || [ "${env,,}" = "sqa-beta" ]; } then
          image="mirth-server"
     elif [ "${application,,}" = "governance-client" ]; then
          image="pghd-governance-mapping-tool"
     elif [ "${application,,}" = "governance-service" ]; then
          image=" pghd-governance-mapping-tool-service"
     fi

     echo "$image"
}

if_smartfhir_then_modify_services_for_deployment_service() {
     local application=$1
     shift
     local services=("$@")
     local modified_services=()
     if [[ ${application,,} = "smartfhir" ]]; then
           for service in "${services[@]}"; do
                    if [ "${service,,}" != "deployment" ]; then
                         modified_services+=("$service")
                    fi
               done
          modified_services+=("Main" "HFD")
     else
          modified_services=("${services[@]}")
     fi

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

return_issue_type_id_based_off_of_service() {
     local service=$1
     if [[ "${service,,}" = "deployment" ]] || [[ "${service,,}" = "main" ]] || [[ "${service,,}" = "hfd" ]]; then
          echo "10011"
     else
          echo "10008"
     fi
}

return_list_of_issue_type_ids() {
     local services=("$@")
     map return_issue_type_id_based_off_of_service "${services[@]}"
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

get_last_child_ticket_number() {
     local last_child_ticket_number
     last_child_ticket_number=$(awk -F'"' '/"key":/ {print $8}' create-child-ticket-test-subtask.out | sed 's/POP-//')
     echo "$last_child_ticket_number"
}

return_child_ticket_list() {
     local application=$1
     shift
     local input_services=("$@")
     local services
     services=$(clean_all_services "$application" "${input_services[@]}")
     local child_tickets
     local ticket_numbers
     # shellcheck disable=SC2207
     ticket_numbers=($(create_list_of_ticket_numbers "${services[@]}"))
     prefix=$(get_project_prefix)

     child_tickets=$(map add_prefix_to_tickets "${ticket_numbers[@]}")

     echo "${child_tickets[@]}"
}

create_list_of_ticket_numbers() {
     services=("$@")
     local last_child_ticket_num
     local num_of_child_tickets
     local child_ticket_numbers
     last_child_ticket_num=$(get_last_child_ticket_number)
     num_of_child_tickets=$(get_number_of_services "${services[@]}")
     for ((i=last_child_ticket_num-num_of_child_tickets; i<=last_child_ticket_num; i++)); do
               child_ticket_numbers+=("$i")
     done
     echo "${child_ticket_numbers[@]}"
}

add_prefix_to_tickets() {
     local ticket_number=$1
     local prefix
     prefix=$(get_project_prefix)
     echo "${prefix}${ticket_number}"
}

create_child_ticket_summary_text() {
     local env=$1
     local image=$2
     local app_version=$3
     local application=$4
     local service=$5

     echo "${env}: Deploy ${image}:$app_version for ${application} to ${service}"

     if [[ "${env,,}" == "prod" ]] || [[ "${env,,}" == "prod-beta" ]]; then
          create_parent_ticket_summary "${env}" "${image}" "${app_version}" "${application}" "${service}"
     else
          echo "${env}: Deploy ${image}:$app_version for ${application} to ${service}"
     fi
}

create_parent_ticket_summary() {
     local env=$1
     local image=$2
     local app_version=$3
     local application=$4
     local service=$5

     echo "${env}: Deploy ${image}:$app_version for ${application} to ${service} - Parent Ticket"
}

create_ticket_summary_list() {
     local env=$1
     local image=$2
     local app_version=$3
     local application=$4
     shift 4
     local services=("$@")


     echo "Debug: env=$1, image=$2, app_version=$3, application=$4, services=${*:5}"
     # Helper function to be used by map
         generate_summary_for_service() {
             local service=$1
             create_child_ticket_summary_text "$env" "$image" "$app_version" "$application" "$service"
         }

    # Use the map function to apply `generate_summary_for_service` to all services
    local ticket_summaries
    ticket_summaries=$(map generate_summary_for_service "${services[@]}")

    echo "Debug: Final ticket summaries=(${ticket_summaries})"
    echo "$ticket_summaries"
}

get_next_step_symbol() {
     echo " *<---- This sub-task is for this step\* ⭐"
}

# Create a description for a ticket
create_ticket_description() {
    local is_vault_ticket=$1
    local vault_description=$2
    local image=$3
    local app_version=$4
    local service=$5

    if [[ "$is_vault_ticket" == "true" ]]; then
        echo "${vault_description} \n \n Deploy: ${image}:$app_version to ${service} \n"
    else
        echo "Deploy: ${image}:$app_version to ${service} \n"
    fi
}

generate_description() {
    local index=$1
    local child_tickets_count=$2
    local vault_description=$3
    local image=$4
    local app_version=$5
    local service=$6
    local is_vault_ticket="false"

    # Create the base description
    local description
    description=$(create_ticket_description "$is_vault_ticket" "$vault_description" "$image" "$app_version" "$service")

    # Remove previous "next step" symbol if necessary
    if ((index > 0)); then
        description=$(remove_previous_next_step "$description")
    fi

    # Add "next step" symbol to the next description if it's not the last one
    if ((index < child_tickets_count - 1)); then
        description=$(add_next_step_to_description "$description")
    fi

    echo "$description"
}

generate_all_descriptions() {
    local vault_description=$1
    local image=$2
    local app_version=$3
    shift 3
    local services=("$@")
    local descriptions=()
    local child_tickets_count=${#services[@]}

    for ((i = 0; i < child_tickets_count; i++)); do
        descriptions+=("$(generate_description "$i" "$child_tickets_count" "$vault_description" "$image" "$app_version" "${services[i]}")")
    done

    echo "${descriptions[@]}"
}


# Remove "next step" indicator from a description
remove_previous_next_step() {
    local description=$1
    local next_step_symbol
    next_step_symbol=$(get_next_step_symbol)
    echo "${description}" | sed "s/ ${next_step_symbol}//g"
}

# Add "next step" indicator to a description
add_next_step_to_description() {
    local description=$1
    local next_step_symbol
    next_step_symbol=$(get_next_step_symbol)
    echo "${description} ${next_step_symbol}"
}


