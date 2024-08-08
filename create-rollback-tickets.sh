#!/bin/bash

token=$1
rollback_tickets=("${@:2}")
echo "Rollback Tickets before cleaning: ${rollback_tickets[*]}"

project_id="10007"

cleaned_rollback_tickets=()
# This loop will remove all the un wanted characters from the services array
for ticket in "${rollback_tickets[@]}"; do
  cleaned_rollback_ticket="${ticket//[\[\],]/}"
  cleaned_rollback_tickets+=("$cleaned_rollback_ticket")
done

# Overwrites the original service array with the cleaned version of service array
rollback_tickets=("${cleaned_rollback_tickets[@]}")
parent_ticket=${rollback_tickets[0]}
echo "Rollback Tickets after cleaning: ${rollback_tickets[*]}"


rollback_ticket_summaries=()
ticket_summary=$(curl -s GET \
                         -u norman.moon@aboutobjects.com:"$token" \
                         "https://normanmoon.atlassian.net/rest/api/2/issue/${rollback_tickets[0]}" | \
                                                                                        json_pp | \
                                                                                        grep summary )

echo "issuetype: ${issuetype}"
cleaned_ticket_summary=$(echo "$ticket_summary" | sed 's/summary//g')
cleaned_ticket_summary=$(echo "$cleaned_ticket_summary" | tr -d '",:')
rollback_ticket_summaries+=("${cleaned_ticket_summary}")

parent_description=$(curl -s GET \
                         -u norman.moon@aboutobjects.com:"$token" \
                         "https://normanmoon.atlassian.net/rest/api/2/issue/${rollback_tickets[0]}" | \
                                                                                        json_pp | \
                                                                                        grep description | \
                                                                                        grep -w Sequence)

cleaned_parent_description=$(echo "$parent_description" | sed 's/"description" ://g')
cleaned_parent_description=$(echo "$cleaned_parent_description" | tr -d '",')
parent_description=${cleaned_parent_description}
echo "This is the parent description: ${parent_description}"

for ticket in "${rollback_tickets[@]:1}"; do

     current_issuetype=0
     ticket_summary=$(curl -s GET \
                              -u norman.moon@aboutobjects.com:"$token" \
                              "https://normanmoon.atlassian.net/rest/api/2/issue/${ticket}" | \
                                                                                             json_pp | \
                                                                                             grep summary | \
                                                                                             grep -v Parent )


     cleaned_ticket_summary=$(echo "$ticket_summary" | sed 's/summary//g')
     cleaned_ticket_summary=$(echo "$cleaned_ticket_summary" | tr -d '",:')
     # Change the summary string into an array and plug in the word ROLLBACK into it
     IFS=' ' read -r -a cleaned_ticket_summary_array <<< "$cleaned_ticket_summary"
     cleaned_ticket_summary_array=( "${cleaned_ticket_summary_array[@]:0:1}" "ROLLBACK" "${cleaned_ticket_summary_array[@]:1}")

     current_ticket_summary="${cleaned_ticket_summary_array[*]}"
     rollback_ticket_summaries+=("${current_ticket_summary}")
     ticket_description=$(curl -s GET \
                              -u norman.moon@aboutobjects.com:"$token" \
                              "https://normanmoon.atlassian.net/rest/api/2/issue/${ticket}" | \
                                                                                             json_pp | \
                                                                                             grep description | \
                                                                                             grep -w Sequence)

     cleaned_ticket_description=$(echo "$ticket_description" | sed 's/"description" ://g')
     cleaned_ticket_description=$(echo "$cleaned_ticket_description" | tr -d '",')

     echo "ticket description for ${ticket}: ${cleaned_ticket_description}"]

     if [[ ${cleaned_ticket_summary,,} == *"deployment"* ]]; then
          current_issuetype=10011
          issuetype+=current_issuetype

     else
          current_issuetype=10008
          issuetype+=current_issuetype
     fi

     if ((current_issuetype==10011)); then

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
                              "$current_ticket_summary" \
                              "$project_id" \
                              "$current_issuetype" \
                              "$parent_ticket" \
                              "$parent_description")

          curl -v -i -X POST \
                 -u norman.moon@aboutobjects.com:$token \
                 -H "Content-Type:application/json" \
                 -H "Accept: application/json" \
                 -H "X-Atlassian-Token:no-check" \
                 "https://normanmoon.atlassian.net/rest/api/2/issue/" \
                 -d \
                 "$json_final" \
                 -o create-child-ticket-test-subtask.out
     else
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
                                        "$current_ticket_summary" \
                                        "$project_id" \
                                        "$current_issuetype" \
                                        "$parent_ticket" \
                                        "$parent_description")

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

echo "This is the last ticket made: $(awk -F'"' '/"key":/ {print $8}' create-child-ticket-test-subtask.out | sed 's/COMP-//')"


echo "These are the ticket summaries: ${rollback_ticket_summaries[*]}"


