#!/bin/bash

rollback=$1
rollback_tickets=("${@:2}")

cleaned_rollback_tickets=()
# This loop will remove all the un wanted characters from the services array
for ticket in "${rollback_tickets[@]}"; do
  cleaned_rollback_ticket="${ticket//[\[\],]/}"
  cleaned_rollback_tickets+=("$cleaned_rollback_ticket")
done

# Overwrites the original service array with the cleaned version of service array
rollback_tickets=("${cleaned_rollback_tickets[@]}")

if [ "$rollback" = true ]; then
     rollback_ticket_summaries=()
     for ticket in "${rollback_tickets[@]}"; do

          rollback_ticket_summaries+=("$(curl -s "https://jira.atlassian.com/rest/api/2/issue/${ticket}" | grep -Po '"summary":.*?[^\\]"')")

     done

     echo "These are the ticket summaries: ${rollback_ticket_summaries[*]}"
fi

