#!/bin/bash

token=$1
rollback_tickets=("${@:2}")
echo "Rollback Tickets before cleaning: ${rollback_tickets[*]}"

cleaned_rollback_tickets=()
# This loop will remove all the un wanted characters from the services array
for ticket in "${rollback_tickets[@]}"; do
  cleaned_rollback_ticket="${ticket//[\[\],]/}"
  cleaned_rollback_tickets+=("$cleaned_rollback_ticket")
done

# Overwrites the original service array with the cleaned version of service array
rollback_tickets=("${cleaned_rollback_tickets[@]}")
echo "Rollback Tickets after cleaning: ${rollback_tickets[*]}"

issuetypes=()

rollback_ticket_summaries=()
ticket_summary=$(curl GET \
                         -u norman.moon@aboutobjects.com:"$token" \
                         "https://normanmoon.atlassian.net/rest/api/2/issue/${rollback_tickets[0]}" | \
                                                                                        json_pp | \
                                                                                        grep summary )

issuetype=$(curl GET \
                         -u norman.moon@aboutobjects.com:"$token" \
                         "https://normanmoon.atlassian.net/rest/api/2/issue/${rollback_tickets[1]}" | \
                                                                                      json_pp | \
                                                                                      grep issuetype )
echo "issuetype: ${issuetype}"
cleaned_ticket_summary=$(echo "$ticket_summary" | sed 's/summary//g')
cleaned_ticket_summary=$(echo "$cleaned_ticket_summary" | tr -d '",:')
rollback_ticket_summaries+=("${ticket_summary}")

for ticket in "${rollback_tickets[@]:1}"; do

     ticket_summary=$(curl GET \
                              -u norman.moon@aboutobjects.com:"$token" \
                              "https://normanmoon.atlassian.net/rest/api/2/issue/${ticket}" | \
                                                                                             json_pp | \
                                                                                             grep summary | \
                                                                                             grep -v Parent )
     cleaned_ticket_summary=$(echo "$ticket_summary" | sed 's/summary//g')
     cleaned_ticket_summary=$(echo "$cleaned_ticket_summary" | tr -d '",:')
     rollback_ticket_summaries+=("${cleaned_ticket_summary}")
done




echo "These are the ticket summaries: ${rollback_ticket_summaries[*]}"


