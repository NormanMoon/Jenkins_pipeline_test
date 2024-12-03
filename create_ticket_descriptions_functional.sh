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
     env=$2
     application=$3
     app_version=$4
     release_type=$5
     vault_description="$6"
     shift 6
     input_services=("$@")

     local child_ticket_list
     local services
     local project_id
     project_id=$(get_project_id)
     services=($(clean_all_services "$application" "${input_services[@]}"))

     local issue_type_ids=()
     local parent_ticket
     parent_ticket=$(get_parent_ticket "$env" "$application")

     # shellcheck disable=SC2207
     issue_type_ids=($(return_list_of_issue_type_ids "${services[@]}"))
     local image
     image=$(get_image "$application")

     # shellcheck disable=SC2207
     child_ticket_list=($(return_child_ticket_list "$application" "${services[@]}"))
     for i in "${child_ticket_list[@]}"; do
          echo "$i"

     done
     echo "$image"


}
# Call main with all script arguments
main "$@"