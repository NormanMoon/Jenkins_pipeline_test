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

     local services
     # Clean services and retrieve necessary data
     # shellcheck disable=SC2207
     local services=($(clean_all_services "$application" "${input_services[@]}"))

     # shellcheck disable=SC2207
     local child_tickets=($(return_child_ticket_list "$application" "${services[@]}"))


     # Initialize description array
     local descriptions=()


     # shellcheck disable=SC2207

     descriptions=($(generate_all_descriptions_for_one_ticket "$vault_description" "$image" "$app_version" "${services[@]}"))


     # Output for debugging
     echo "Child tickets: ${child_tickets[*]}"
     echo "Descriptions: ${descriptions[*]}"


}
# Call main with all script arguments
main "$@"