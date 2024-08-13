#!/bin/bash

# Project ID
project_id="10007"

token=$1
services=("${@:2}") # Get all arguments starting from the second one as an array
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
services=("${cleaned_services[@]}")

for ((j=0; j<${#services[@]}; j++)) do
     echo "Service Name : ${services[j],,}"
     if [[ "${services[j],,}" = "deployment" ]]; then
          issuetype_id+=("10011")
     else
          issuetype_id+=("10008")
     fi
done

#Parent ticket
# This will awk the parent key from create-parent-ticket-test.out in the last line
parent=$(awk -F'"' '/"key":/ {print $8}' create-parent-ticket-test.out)
echo "parent ticket: $parent"

child_tickets=("Deployment...\n Sequence of Steps:\n\n")

for ((j=0; j<${#issuetype_id[@]}; j++)) do
     child_tickets+=("Ticket")
done

echo "ticket types ${issuetype_id[*]}"
echo "children types ${child_tickets[*]}"


##################################################################################################################


description=("${child_tickets[0]}")

for ((j=1; j<${#child_tickets[@]}; j++)) do


    description+=("${child_tickets[j]}")

done
description+=(" l")


child_tickets_keys=()

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
                              "$parent" \
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

          child_tickets_keys+=("$(awk -F'"' '/"key":/ {print $8}' create-child-ticket-test-subtask.out)")


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
                              "$parent" \
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

          child_tickets_keys+=("$(awk -F'"' '/"key":/ {print $8}' create-child-ticket-test-subtask.out)")


     fi


done






