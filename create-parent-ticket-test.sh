#!/bin/bash
set -x

# This is the local Jira token, saved in the Jenkins pipeline
token=$1
application=$2
environment=$3
services=("${@:4}")

# Project ID
project_id="10008" # This is the project ID for project POP
# This is always the same for parent tickets
issuetype_id="10000"

summary="Parent"
description="Parent"



# Cleaning up the services
cleaned_services=()
# This loop will remove all the un wanted characters from the services array
for service in "${services[@]}"; do
  cleaned_service="${service//[\[\],]/}"
  cleaned_services+=("$cleaned_service")
done
# Overwrites the original service array with the cleaned version of service array
services=("${cleaned_services[@]}")

# This goes through the array services, if it contains main, hfd, or archive, and the application is not smartfhir then
# it will exit the script, else it will continue.
for service in "${services[@]}"; do
     if [ "${service,,}" = "hfd" ] || [ "${service,,}" = "main" ] || [ "${service,,}" = "archive" ]; then
          if [ "${application,,}" != "smartfhir" ]; then
               echo "You are creating HFD, Main, and Archive tickets, but your application is no Smartfhir!"
               exit 0
          fi
     fi
done



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
                         "$summary" \
                         "$project_id" \
                         "$issuetype_id" \
                         "$description")

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
cat create-parent-ticket-test.out
