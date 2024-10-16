#!/bin/bash
set -x

# Project ID
project_id="10008"

token=$1
env=$2
application=$3
services=("${@:4}") # Get all arguments starting from the second one as an array
# Issue Type ID list (Patch, Configuration) (consul, staff, veteran,l=configuration, deployment=patch)
issuetype_id=()
cleaned_services=()
# This loop will remove all the un wanted characters from the services array

echo "services at top of script: ${services[*]}"
for service in "${services[@]}"; do
  cleaned_service="${service//[\[\],]/}"
  cleaned_services+=("$cleaned_service")
done
echo "cleaned services at top of script: ${cleaned_services[*]}"
# Overwrites the original service array with the cleaned version of service array
if [ ${application,,} = "smartfhir" ]; then
     for ((j=0; j<${#services[@]}; j++)) do
          if [[ "${services[j],,}" = "deployment" ]]; then
               unset 'services[j]'
          fi
     done
     # Reindex the array after unsetting
     services=("${services[@]}")
     services+=("Main")
     services+=("HFD")
     services+=("Arch")
fi


services=("${cleaned_services[@]}")
echo "services after cleaning: ${services[*]}"

for ((j=0; j<${#services[@]}; j++)) do
     echo "Service Name : ${services[j],,}"

     if [[ "${services[j],,}" = "deployment" ]] || [[ "${services[j],,}" = "main" ]] || [[ "${services[j],,}" = "HFD" ]] || [[ "${services[j],,}" = "arch" ]]; then
          issuetype_id+=("10011")
     else
          issuetype_id+=("10008")
     fi
done

#Parent ticket
# This will awk the parent_ticket key from create-parent_ticket-ticket-test.out in the last line
parent_ticket=$(awk -F'"' '/"key":/ {print $8}' create-parent-ticket-test.out)

child_tickets=("Deployment...\n Sequence of Steps:\n\n")

if [[ "${env,,}" == "sqa" ]] || [[ "${env,,}" == "sqa-beta" ]]; then
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


for ((j=0; j<${#issuetype_id[@]}; j++)) do
     child_tickets+=("Ticket")
done

description=("${child_tickets[0]}")

for ((j=1; j<${#child_tickets[@]}; j++)) do
    description+=("${child_tickets[j]}")
done


for ((j=0; j<${#issuetype_id[@]}; j++)) do

     if ((issuetype_id[j]==10008))  #Task
     then
          summary=${child_tickets[j+1]}
          temp_description=${description[*]}
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
          summary=${child_tickets[j+1]}
          temp_description=${description[*]}
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

     fi

done

cat create-child-ticket-test-subtask.out


