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
     # shellcheck disable=SC2207
     services=($(clean_all_services "$application" "${input_services[@]}"))

     local issue_type_ids=()
     local parent_ticket
     parent_ticket=$(get_parent_ticket "$env" "$application")

     # shellcheck disable=SC2207
     issue_type_ids=($(return_list_of_issue_type_ids "${services[@]}"))
     local image
     image=$(get_image "$application")


     local child_tickets
     # shellcheck disable=SC2207
     child_tickets=($(return_child_ticket_list "$application" "${services[@]}"))


     # shellcheck disable=SC2207
     child_ticket_summary_list=($(create_ticket_summary_list "$env" "$image" "$app_version" "$application" "${services[@]}"))


     echo "Services: ${services[*]}"
     echo "Child tickets: ${child_tickets[*]}"
     echo "Ticket summaries: ${child_ticket_summary_list[*]}"

}
# Call main with all script arguments
main "$@"