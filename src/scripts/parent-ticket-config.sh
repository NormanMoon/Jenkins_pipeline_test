#!/bin/bash
set -x

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

project_id="10008" # This is the project ID for project POP
# This is always the same for parent tickets
issuetype_id="10000"

token=$1
application=$2
environment=$3
# The services the tickets are being made for
services=("${@:4}")


cd "$PROJECT_ROOT" || exit
# Compile and run Java program
javac -d bin utils/service_cleaner.java
cleaned_services_string=$(java -cp bin utils.service_cleaner "$application" "${services[@]}")
# Convert the space-separated string back into an array
IFS=' ' read -r -a services <<< "$cleaned_services_string"

parent_ticket_summary="parent"
parent_description="parent"




if [[ "${environment,,}" != "sqa" ]] && [[ "${environment,,}" != "sqa-beta" ]]; then
     template='{

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
     }'

     json_final=$(printf "$template" \
                         "$parent_ticket_summary" \
                         "$project_id" \
                         "$issuetype_id" \
                         "$parent_description")

     curl -v -i -X POST \
               -u norman.moon@aboutobjects.com:"$token" \
               -H "Content-Type:application/json" \
               -H "Accept: application/json" \
               -H "X-Atlassian-Token:no-check" \
               "https://normanmoon.atlassian.net/rest/api/2/issue/" \
               -d \
               "$json_final" \
               -o create-parent-ticket-test.out
fi
cat create-parent-ticket.out

