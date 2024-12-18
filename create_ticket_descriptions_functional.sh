#!/bin/bash
set -x

source "${WORKSPACE}"/lib/utils.sh

create_json_string() {
     local summary=$1
     local description=$2

     printf '{
          "fields" : {
          "summary" : "%s",
          "description" : "%s"
          }
     }'   "$summary" \
          "$description"

}

main() {
     local token=$1
     local env=$2
     local application=$3
     local app_version=$4
     local release_type=$5
     local vault_description="$6"
     shift 6
     local input_services=("$@")

     local child_ticket_list
     local services
     local project_id
     project_id=$(get_project_id)
     # Clean services and retrieve necessary data
     local services=($(clean_all_services "$application" "${input_services[@]}"))
     local image=$(get_image "$application")
     local child_tickets=($(return_child_ticket_list "$application" "${services[@]}"))
     local summaries=($(create_ticket_summary_list "$env" "$image" "$app_version" "$application" "${services[@]}"))

     # Initialize description array
     local descriptions=()
     local next_step_symbol
     next_step_symbol=$(get_next_step_symbol)

     # Use map to create descriptions
     for ((i=0; i<${#child_tickets[@]}; i++)); do
       local is_vault_ticket=$(check_for_vault "${summaries[i]}")

       # Create the new description
       descriptions[i]=$(create_ticket_description "$is_vault_ticket" "$vault_description" "$image" "$app_version" "${services[i]}")

       # Remove previous "next step" symbol if necessary
       if ((i > 0)); then
           descriptions[i]=$(remove_previous_next_step "${descriptions[i]}")
       fi

       # Add "next step" symbol to the next description
       if ((i < ${#child_tickets[@]} - 1)); then
           descriptions[i+1]=$(add_next_step_to_description "${descriptions[i+1]}")
       fi
     done

     # Escape newlines for JSON
     local json_descriptions=()
     for desc in "${descriptions[@]}"; do
       json_descriptions+=("$(echo "$desc" | sed ':a;N;$!ba;s/\n/\\n/g')")
     done

     # Output for debugging
     echo "Child tickets: ${child_tickets[*]}"
     echo "Descriptions: ${json_descriptions[*]}"
}
# Call main with all script arguments
main "$@"