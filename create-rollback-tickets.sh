#!/bin/bash
set -x

token=$1
rollback_version=$2
parent_child_tickets=("${@:3}")

echo "Rollback Tickets before cleaning: ${parent_child_tickets[*]}"

project_id="10007"

prefix="POP-"
# This is an array to specify the issue type for each ticket. The order should be the same as order the rollback tickets are being made
issuetypes=()
# New Rollback ticket summaries in same order as the issuetypes()
rollback_ticket_summaries=()

# a separate array to hold the tickets from the parent_child_tickets but in a clean format, so no extra spaces, or symbols
cleaned_parent_child_tickets=()
# This loop will remove all the un wanted characters from the services array
for ticket in "${parent_child_tickets[@]}"; do
  cleaned_rollback_ticket="${ticket//[\[\],]/}"
  cleaned_rollback_tickets+=("$cleaned_rollback_ticket")
done

# Overwrites the original service array with the cleaned version of service array
parent_child_tickets=("${cleaned_parent_child_tickets[@]}")
parent_ticket=${parent_child_tickets[0]} # The first element in the array should always be the parent
echo "Rollback Tickets after cleaning: ${parent_child_tickets[*]}"

curl -s -u "username:apitoken" "https://normanmoon.atlassian.net/rest/api/2/issue/" | cat

ticket_summary=$(curl -s GET \
                         -u norman.moon@aboutobjects.com:"$token" \
                         "https://normanmoon.atlassian.net/rest/api/2/issue/${parent_child_tickets[0]}" | \
                                                                                        json_pp | \
                                                                                        grep summary )

echo "issuetype: ${issuetypes}"
cleaned_ticket_summary=$(echo "$ticket_summary" | sed 's/summary//g')
cleaned_ticket_summary=$(echo "$cleaned_ticket_summary" | tr -d '",:')
rollback_ticket_summaries+=("${cleaned_ticket_summary}")

parent_description=$(curl -s GET \
                         -u norman.moon@aboutobjects.com:"$token" \
                         "https://normanmoon.atlassian.net/rest/api/2/issue/${parent_child_tickets[0]}" | \
                                                                                        json_pp | \
                                                                                        grep description | \
                                                                                        grep -w Sequence)

cleaned_parent_description=$(echo "$parent_description" | sed 's/"description" ://g')
cleaned_parent_description=$(echo "$cleaned_parent_description" | tr -d '",')
parent_description=${cleaned_parent_description}
parent_description+=" "
echo "This is the parent description: ${parent_description}"

# This is the number of rollback tickets being made. Its used for updating the ticket descriptions
number_of_rollback_tickets=$((${#parent_child_tickets[@]}-1))

for ticket in "${parent_child_tickets[@]:1}"; do

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

     echo "The current ticket summary: ${cleaned_ticket_summary}"

     if [[ ${cleaned_ticket_summary,,} == *"deployment"* ]]; then
          current_issuetype=10011
          issuetypes+=current_issuetype

     else
          current_issuetype=10008
          issuetypes+=current_issuetype
     fi
     echo "The current ticket issuetype: ${current_issuetype}"
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

          curl -v -s -i -X POST \
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

                    curl -v -s -i -X POST \
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

latest_rollback_ticket_number="$(awk -F'"' '/"key":/ {print $8}' create-child-ticket-test-subtask.out | sed 's/COMP-//')"


echo "These are the ticket summaries: ${rollback_ticket_summaries[*]}"

# This is the updating the descriptions for the new rollback tickets
for ((i=$((number_of_rollback_tickets-1)); i >= 0; i -- )); do
     current_rollback_ticket_number=$((latest_rollback_ticket_number-i))
     current_rollback_ticket="COMP-${current_rollback_ticket_number}"
     parent_description+="\n${current_rollback_ticket}"
done

echo"This is the current ticket being added into the parent description: ${current_rollback_ticket_number}"

temp_parent_description="${parent_description[*]}"

template='{
    "fields" : {
      "description" : "%s"
    }
  }'

json_final=$(printf "$template" \
     "$temp_parent_description")

curl -v -i -X PUT \
  -u norman.moon@aboutobjects.com:$token \
  -H "Content-Type:application/json" \
  -H "Accept: application/json" \
  -H "X-Atlassian-Token:no-check" \
  "https://normanmoon.atlassian.net/rest/api/2/issue/${parent_ticket}" \
  -d \
  "$json_final" \
  -o update-task-test.out


next_step="${bold} <---- current step ★${normal}"


# Initialize an empty array for children_tickets
children_tickets=()

IFS=' ' read -r -a temp <<< "$temp_parent_description"
for ticket in "${temp[@]}"; do
     if [[ $ticket == *"COMP"* ]]; then
          children_tickets+=("$(echo -e "$ticket" | sed 's/\n//g')")
     fi
done
# Output the filtered results
echo "children_tickets: ${children_tickets[*]}"

delimited_string=$(printf "%s" "$parent_description" | sed 's/\\n/|/g')
# Now split based on the new delimiter
IFS='|' read -r -a parent_description <<< "$delimited_string"

for element in "${parent_description[@]}"; do
    echo "$element"
done


for ((i=0; i<${#children_tickets[@]}; i ++)); do

     if ((i > 0)) &&  [[ ${parent_description[i+2]} == *"${next_step}"* ]]; then
          parent_description[i+2]=$(echo "${parent_description[i+2]}" | sed "s/${next_step}//g")
     fi
     parent_description[i+3]+=${next_step}


     string_description=${parent_description[*]}
     child_ticket="$(echo ${children_tickets[i]} | sed 's/ //g')"
     template='{
               "fields" : {
                 "description" : "%s"
               }
             }'
     json_final=$(printf "$template" \
         "$string_description")

     curl -v -i -X PUT \
               -u norman.moon@aboutobjects.com:$token \
               -H "Content-Type:application/json" \
               -H "Accept: application/json" \
               -H "X-Atlassian-Token:no-check" \
               "https://normanmoon.atlassian.net/rest/api/2/issue/${child_ticket}" \
               -d \
               "$json_final" \
               -o update-task-test.out
done


