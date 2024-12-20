#!/bin/bash
set -x #helpful for troubleshooting


prefix="POP-"
#Parent ticket
parent_ticket_num=$(awk -F'"' '/"key":/ {print $8}' create-parent-ticket-test.out | sed 's/POP-//')
parent_ticket="POP-${parent_ticket_num}"
last_child_ticket_num=$(awk -F'"' '/"key":/ {print $8}' create-child-ticket-test-subtask.out | sed 's/POP-//')


token=$1
env=$2
application=$3
app_version=$4
release_type=$5
vault_description="$6"
services=("${@:7}")



#This will remove the ',' from the release_type and
cleaned_release_type="${release_type//[\,]/}"
# This will overwrite the original release_type with the cleaned_release_type
release_type=$cleaned_release_type
# This removes the {} from application version
cleaned_app_version="${app_version//[\{\}]/}"
# This will overwrite the original app_version with the cleaned_app_version
app_version=$cleaned_app_version
# Remove unwanted characters from the vault description
vault_description="${vault_description//[\[\],]/}"

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
     for ((j=0; j<${#cleaned_services[@]}; j++)) do
          if [[ "${cleaned_services[j],,}" = "deployment" ]]; then
               unset 'cleaned_services[j]'
          fi
     done
     # Reindex the array after unsetting
     cleaned_services=("${cleaned_services[@]}")
     cleaned_services+=("Main")
     cleaned_services+=("HFD")
fi
services=("${cleaned_services[@]}")
echo "services after cleaning: ${services[*]}"

# These if statements are meant to convert the application to the appropriate image that will be used in the tickets summary
image="" # This is the image that will be used in the ticket summary
if [ "${application,,}" = "federator" ]; then
     image=" pghd-fhir-federator"
elif [ "${application,,}" = "smartfhir" ]; then
     image="smart-pgd-fhir-service"
elif [ "${application,,}" = "mirth" ] && { [ "${env,,}" = "prod" ] || [ "${env,,}" = "sqa" ]; } then
     image="tmc-v2"
elif [ "${application,,}" = "mirth" ] && { [ "${env,,}" = "prod-beta" ] || [ "${env,,}" = "sqa-beta" ]; } then
     image="mirth-server"
elif [ "${application,,}" = "governance-client" ]; then
     image="pghd-governance-mapping-tool"
elif [ "${application,,}" = "governance-service" ]; then
     image=" pghd-governance-mapping-tool-service"
fi


# Place all child tickets in order here...
child_tickets=()

num_of_child_tickets=${#services[@]}-1

# This for loop will go to one ticket ahead of the parent ticket and then loop till it reaches the last child ticket
# all the tickets in between are added to the child_ticket array as a child ticket
for ((i=last_child_ticket_num-num_of_child_tickets; i<=last_child_ticket_num; i++)); do
     child_tickets+=("${prefix}${i}")
done
echo " These are the child tickets: ${child_tickets[*]}"

# This creates the ticket description for each ticket (service)
ticket_summaries=()
for ((i=0; i<=${#services[@]}; i++)); do
     if [ "${services[i],,}" = "vault" ]; then

          ticket_summaries+=("${env}: Vault update for ${application}")
          vault_description="${vault_description} \n"

     # If the ticket is a deployment ticket, then "Deploy" will be in the summary, else its "Change"
     elif [ "${services[i],,}" = "deployment" ] && [ "${application,,}" = "smartfhir" ]; then
          ticket_summaries+=("${env}: Deploy ${image}:$app_version for ${application} to Main")
          ticket_summaries+=("${env}: Deploy ${image}:$app_version for ${application} to HFD")
     elif [ "${services[i],,}" = "deployment" ]; then
          ticket_summaries+=("${env}: Deploy ${image}:$app_version for ${application}")
     else
          ticket_summaries+=("${env}: Change ${image}:$app_version for ${application} ${services[i]}")
     fi
done

# This is the next step string that is added to the current step of the ticket description
next_step=" *<---- This sub-task is for this step* ⭐"

# This initializes the description for the parent ticket
description=("${env}: ${release_type} Release of ${application} $app_version \n \n *Sequence of Steps:*")
for ((j=0; j<${#child_tickets[@]}; j++)); do
     description+=("\n${child_tickets[j]} ${ticket_summaries[j]}")
done



#Updates Parent Ticket Description
if [[ "${env,,}" == "prod" ]] || [[ "${env,,}" == "prod-beta" ]]; then
     string_description=${description[*]}
     parent_summary="${env} ${release_type} Release of ${application} $app_version - Parent Ticket"
     template='{
         "fields" : {
          "summary" : "%s",
           "description" : "%s"
         }
       }'


     json_final=$(printf "$template" \
          "$parent_summary" \
          "$string_description")

     curl -v -i -X PUT \
       -u norman.moon@aboutobjects.com:$token \
       -H "Content-Type:application/json" \
       -H "Accept: application/json" \
       -H "X-Atlassian-Token:no-check" \
       "https://normanmoon.atlassian.net/rest/api/2/issue/${parent_ticket}" \
       -d \
       "$json_final" \
       -o update-task-test.out
fi
cat update-task-test.out

for ((i=0; i<${#child_tickets[@]}; i++)); do
     # If the description line has the word vault in it (meaning this current ticket is a vault ticket) then we add the
     # vault description to the top of the ticket description, if its not a vault ticket, then we dont add the vault description
     # to the top of the current ticket description
     if [[ ${ticket_summaries[i],,} == *"vault"* ]]; then
          description[0]="${vault_description} \n \n Deploy: ${image}:$app_version to ${services[i]} \n \n *Sequence of Steps:*"
     else
          description[0]="Deploy: ${image}:$app_version to ${services[i]} \n \n *Sequence of Steps:*"
     fi

     # description[i] represents the last ticket because the size of description is +1 than the size of child_tickets

     # This will check if the last ticket has *<---- This sub-task is for this step* ⭐, if it does then we delete it
     if ((i > 0)) && [[ ${description[i]} == *"${next_step}"* ]]; then
          description[i]=$(echo "${description[i]}" | sed "s/ \*<---- This sub-task is for this step\* ⭐//g")
     fi
     description[i+1]+=${next_step}

     string_description=${description[*]}
     summary_temp=${ticket_summaries[i]}

     if [[ "${env,,}" == "sqa" ]] || [[ "${env,,}" == "sqa-beta" ]]; then
          if [[ ${ticket_summaries[i],,} == *"vault"* ]]; then
               string_description=${vault_description}
          else
               string_description=${ticket_summaries[i]}
          fi
     fi
     string_description=$(echo "$string_description" | sed ':a;N;$!ba;s/\n/\\n/g')

  template='{
      "fields" : {
        "summary" : "%s",
        "description" : "%s"
      }
    }'

     json_final=$(printf "$template" \
          "$summary_temp" \
          "$string_description")

     echo "${json_final}"


     curl -v -i -X PUT \
          -u norman.moon@aboutobjects.com:$token \
          -H "Content-Type:application/json" \
          -H "Accept: application/json" \
          -H "X-Atlassian-Token:no-check" \
          "https://normanmoon.atlassian.net/rest/api/2/issue/${child_tickets[i]}" \
          -d \
          "$json_final" \
          -o update-task-test.out

     cat update-task-test.out
done

true > pr_ticket_list.txt
for ((i=0; i<${#child_tickets[@]}; i++)); do
     if [[ ${ticket_summaries[i],,} == *"staff"* ]]; then
          echo "${child_tickets[i]}" >> pr_ticket_list.txt
     elif [[ ${ticket_summaries[i],,} == *"veteran"* ]]; then
          echo "${child_tickets[i]}" >> pr_ticket_list.txt
     elif [[ ${ticket_summaries[i],,} == *"consul"* ]]; then
          echo "${child_tickets[i]}" >> pr_ticket_list.txt
     fi
done

cat pr_ticket_list.txt


child_tickets_arr=()

while IFS="" read -r ticket
do
     child_tickets_arr+=("$ticket")
done < pr_ticket_list.txt

for l in "${child_tickets_arr[@]}"; do
     echo "$l"
done



