#!/bin/bash

rollback=$1
rollback_tickets=$2

if [ rollback = true ]; then
     rollback_ticket_summaries=()
     for ticket in "${rollback_tickets[@]}"; do

          rollback_ticket_summaries+=("$(curl -s "https://jira.atlassian.com/rest/api/2/issue/${ticket}" | grep -Po '"summary":.*?[^\\]"')")

     done

     echo "These are the ticket summaries: ${rollback_ticket_summaries[*]}"
fi

