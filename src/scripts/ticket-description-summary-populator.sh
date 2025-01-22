#!/bin/bash
set -x


#Parent ticket
prefix="POP-"
#Parent ticket
pwd
parent_ticket_num=$(awk -F'"' '/"key":/ {print $8}' create-parent-ticket.out | sed 's/NGD-//')
# This takes the parent ticket number and adds the prefix to the beginning of it
parent_ticket="NGD-${parent_ticket_num}"
# This is the latest ticket number made from the children ticket. This is needed because later in the script we find the
# the other children ticket numbers by subtracting from the latest child ticket number
last_child_ticket_num=$(awk -F'"' '/"key":/ {print $8}' create-child-tickets.out | sed 's/NGD-//')


# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

token=$1 # The environment taken from Jenkins Pipeline
env=$2
# Application taken from Jenkins Pipeline
application=$3
# The application version being deployed
app_version=$4
# The release type
release_type=$5
# This is the vault ticket description when making vault is in the services of tickets to be made
vault_description="$6"
# The services the tickets are being made for
services_input=("${@:7}")
#Child Tickets
num_of_child_tickets=${#services[@]}-1
for ((i=last_child_ticket_num-num_of_child_tickets; i<=last_child_ticket_num; i++)); do
     child_tickets+=("${prefix}${i}")
done
echo " These are the child tickets: ${child_tickets[*]}"


image="pghd-fhir-federator" # This is the image that will be used in the ticket summary
if [ "${application,,}" = "federator" ]; then
     image="pghd-fhir-federator"
elif [ "${application,,}" = "smartfhir" ]; then
     image="smart-pgd-fhir-service"
elif [ "${application,,}" = "mirth" ] && { [ "${env,,}" = "prod" ] || [ "${env,,}" = "sqa" ]; } then
     image="tmc-v2"
elif [ "${application,,}" = "mirth" ] && { [ "${env,,}" = "prod-beta" ] || [ "${env,,}" = "sqa-beta" ]; } then
     image="mirth-server"
elif [ "${application,,}" = "governance-client" ]; then
     image="pghd-governance-mapping-tool"
elif [ "${application,,}" = "governance-service" ]; then
     image="pghd-governance-mapping-tool-service"
fi

# Keywords to keep in services
valid_services=("Vault" "Deployment" "HFD" "Main" "Veteran" "Other")

services=()
for service in "${services_input[@]}"; do
    if [[ " ${valid_services[*]} " == *" $service "* ]]; then
        services+=("$service")
    fi
done

child_tickets=()
for ticket in "${child_tickets_input[@]}"; do
    if [[ ! " ${services[*]} " == *" $ticket "* ]]; then
        child_tickets+=("$ticket")
    fi
done

echo "Filtered Services: ${services[*]}"
echo "Filtered Child Tickets: ${child_tickets[*]}"



#This will remove the ',' from the release_type and
cleaned_release_type="${release_type//[\,]/}"
# This will overwrite the original release_type with the cleaned_release_type
release_type=$cleaned_release_type
# This removes the {} from app version
cleaned_app_version="${app_version//[\{\}]/}"
# This will overwrite the original app_version with the cleaned_app_version
app_version=$cleaned_app_version
# Remove unwanted characters from the vault description
vault_description="${vault_description//[\[\],]/}"

cd "$PROJECT_ROOT" || exit
# Compile and run Java program
javac -d bin utils/service_cleaner.java
cleaned_services_string=$(java -cp bin utils.service_cleaner "$application" "${services[@]}")
# Convert the space-separated string back into an array
OIFS="$IFS"
IFS=' ' read -r -a services <<< "$cleaned_services_string"



other_ticket_summaries=""
for (( i=0; i<${#child_tickets[@]}; i++ )); do
     if [ "${services[i]}" = "Other" ]; then
          ticket_summary=$(curl -s GET \
               -u norman.moon@aboutobjects.com:"$token" \
               "https://normanmoon.atlassian.net/rest/api/2/issue/${ticket}" | \
               json_pp | \
               grep '"fields" : {' -A 1000 | \
               grep '"summary" :' | \
               awk 'NR==2 {print $0}' | \
               cut -d ':' -f2- | \
               sed 's/^[ \t]*//;s/"//g;s/,$//')

          other_ticket_summaries+="| $(echo "${ticket_summary}" | sed "s/'//g" | tr -d '\n' | xargs)"
     fi
done

if [ -z "$other_ticket_summaries" ]; then
    services+=("|")
fi

echo "${services[@]}"

# Compile and run Java program
javac -d bin utils/summary_creator.java
all_summaries=$(java -cp bin utils.summary_creator "$env" "$application" "$image" "$app_version" "$release_type" "$other_ticket_summaries" "${services[@]}" )

# Convert the space-separated string back into an array
OIFS="$IFS"
IFS='|'
read -d '' -r -a summaries <<< "$all_summaries"
echo "This is all the summaries: ${summaries[*]}"
IFS="$OIFS"

# Compile and run Java program
javac -d bin utils/description_creator.java
generated_descriptions=$(java -cp bin utils.description_creator "$env" "$application" "$image" "$app_version" "$release_type" "$vault_description" "${summaries[@]}" "${child_tickets[@]}" "${services[@]}")

# Saves original IFS
OIFS="$IFS"
# Sets IFS to | because the different descriptions are seperated by a | within the string
IFS='|'

# -d sets the delimiter to null, allowing multiline content to be read
# -r prevents backslash escapes from being interpreted
# -a descriptions_array tells the read command to store the input into an array called descriptions_array
read -d '' -r -a descriptions_array <<< "$generated_descriptions"
# Restore original IFS, important to clean up in case other parts use the OIFS
IFS="$OIFS"


for ((i = 0; i < ${#child_tickets[@]}; i++)); do
     if [[ "${services[i]}" = "Other" ]]; then
          ticket_description=$(curl -s GET\
               -u "norman.moon@aboutobjects.com:$token" \
               "https://normanmoon.atlassian.net/rest/api/2/issue/${child_tickets[i]}" | \
               json_pp | \
               grep '"fields" : {' -A 1000 | \
               grep '"description" :' | \
               head -n 1 | \
               cut -d ':' -f2- | \
               sed 's/^[ \t]*//;s/"//g;s/,$//')

          descriptions_array[i+1]="${ticket_description}$'\n \n'${descriptions_array[$i+1]}"
     fi

done

if [[ "${env,,}" == "prod" ]] || [[ "${env,,}" == "prod-beta" ]]; then
     string_description=${descriptions_array[0]}
     parent_summary=${summaries[0]}
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


i=0
for currChildTicket in "${child_tickets[@]}"; do
     template='{
           "fields" : {
             "summary" : "%s",
             "description" : "%s"
           }
         }'

          json_final=$(printf "$template" \
               "${summaries[$i]}" \
               "${descriptions_array[$i]}")

          echo "${json_final}"


          curl -v -i -X PUT \
               -u norman.moon@aboutobjects.com:$token \
               -H "Content-Type:application/json" \
               -H "Accept: application/json" \
               -H "X-Atlassian-Token:no-check" \
               "https://normanmoon.atlassian.net/rest/api/2/issue/${currChildTicket}" \
               -d \
               "$json_final" \
               -o update-task-test.out

          cat update-task-test.out
          (( i+=1 ))
done

