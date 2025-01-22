#!/bin/bash
set -x #helpful for troubleshooting

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

# This is the local Jira token, saved in the Jenkins pipeline
token=$1
environment=$2
application=$3
services=("${@:4}") # Get all arguments starting from the second one as an array

cd "$PROJECT_ROOT" || exit
# Compile and run Java program
javac -d bin utils/service_cleaner.java
OIFS="$IFS"
cleaned_services_string=$(java -cp bin utils.service_cleaner "$application" "${services[@]}")
# Convert the space-separated string back into an array
IFS=' ' read -r -a services <<< "$cleaned_services_string"
IFS="$OIFS"

echo "These are the services: ${services[*]}"

# 13403=configuration , and 12803=patch
# Issue Type ID list (Patch, Configuration) (consul, staff, veteran,l=configuration, deployment=patch)
issuetype_id=()
for ((j=0; j<${#services[@]}; j++)) do
     echo "Service Name : ${services[j],,}"

     if [[ "${services[j],,}" = "deployment" ]] || [[ "${services[j],,}" = "main" ]] || [[ "${services[j],,}" = "hfd" ]] ; then
          issuetype_id+=("10011")
     else
          issuetype_id+=("10008")
     fi
done

child_tickets=("Deployment...\n Sequence of Steps:\n\n")

#project_id=
project_id="17306"

#Parent ticket
# This will awk the parent_ticket key from create-parent_ticket-ticket-test.out in the last line
parent_ticket=$(awk -F'"' '/"key":/ {print $8}' create-parent-ticket.out)

# If the environment is in staging, then we already know the parent_ticket so we can assign that automatically,
# if its not in staging, then we made the parent ticket ourselves, and so we'll pull that from the .out file
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
fi




##################################################################################################################
##################################################################################################################


for ((j=0; j<${#issuetype_id[@]}; j++)) do

     if ((issuetype_id[j]==10008))  #Task
     then
          summary="Ticket"
          temp_description="Ticket"
          temp_issuetype=${issuetype_id[j]}
          template='{

               "fields": {
                    "summary": "%s",
               "project": {
                    "id": "%s"
               },
               "issuetype": {
                  "id": "%s"
               },
               "parent": {
                  "key": "%s"
               },
               "description": "%s"
                }
            }'

          json_final=$(printf "$template" \
                              "$summary" \
                              "$project_id" \
                              "$temp_issuetype" \
                              "$parent_ticket" \
                              "$temp_description")

          curl -v -i -X POST \
                 -u norman.moon@aboutobjects.com:$token \
                 -H "Content-Type:application/json" \
                 -H "Accept: application/json" \
                 -H "X-Atlassian-Token:no-check" \
                 "https://normanmoon.atlassian.net/rest/api/2/issue/" \
                 -d \
                 "$json_final" \
                 -o create-child-ticket-test-subtask.out



     elif ((issuetype_id[j]==10011))  #Bug
     then
          summary="Ticket"
          temp_description="Ticket"
          temp_issuetype=${issuetype_id[j]}
          template='{

               "fields": {
                    "summary": "%s",
               "project": {
                    "id": "%s"
               },
               "issuetype": {
                  "id": "%s"
               },
               "parent": {
                  "key": "%s"
               },
               "description": "%s"
                }
            }'

          json_final=$(printf "$template" \
                              "$summary" \
                              "$project_id" \
                              "$temp_issuetype" \
                              "$parent_ticket" \
                              "$temp_description")

          curl -v -i -X POST \
                 -u norman.moon@aboutobjects.com:$token \
                 -H "Content-Type:application/json" \
                 -H "Accept: application/json" \
                 -H "X-Atlassian-Token:no-check" \
                 "https://normanmoon.atlassian.net/rest/api/2/issue/" \
                 -d \
                 "$json_final" \
                 -o create-child-tickets.out

     fi

done

cat create_child_tickets.out