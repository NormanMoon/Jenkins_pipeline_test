#!/bin/bash

rollback_tickets=("$@")
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

rollback_ticket_summaries=()
for ticket in "${rollback_tickets[@]}"; do

     ticket_summary=("$(curl -s "https://normanmoon.atlassian.net/rest/api/2/issue/${ticket}" | grep -Po '"summary":.*?[^\\]"')")
     rollback_ticket_summaries+=("${ticket_summary[*]}")

done

echo "These are the ticket summaries: ${rollback_ticket_summaries[*]}"


